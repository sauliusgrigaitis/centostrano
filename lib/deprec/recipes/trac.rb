Capistrano.configuration(:must_exist).load do
    
  set :trac_password_file, lambda { "#{trac_path}/conf/users.htdigest" }
  set :trac_pidfile, lambda { "#{deploy_to}/shared/pids/trac.pid" }
  set :tracd_port, '9000'
  set (:trac_path) do
    deploy_to ? "#{deploy_to}/trac" : Capistrano::CLI.prompt('path to trac config')
  end
  set (:trac_account) do
    Capistrano::CLI.prompt('enter new trac user account name')
  end  
  set :trac_passwordfile_exists, true # hack - should check on remote system instead
  
  set :trac_smtp_enabled, true
  
  task :trac_install, :roles => :scm do
    version = 'trac-0.10.4'
    set :src_package, {
      :file => version + '.tar.gz',   
      :md5sum => '52a3a21ad9faafc3b59cbeb87d5a69d2  trac-0.10.4.tar.gz', 
      :dir => version,  
      :url => "http://ftp.edgewall.com/pub/trac/#{version}.tar.gz",
      :unpack => "tar zxf #{version}.tar.gz;",
      :install => 'python ./setup.py install --prefix=/usr/local;'
    }
    enable_universe
    apt.install( {:base => %w(python-sqlite sqlite python-clearsilver)}, :stable )
    deprec.download_src(src_package, src_dir)
    deprec.install_from_src(src_package, src_dir)
  end
  
  task :trac_create_pid_dir, :roles => :scm do
    deprec.mkdir(File.dirname(trac_pidfile))
  end
  
  task :trac_setup, :roles => :scm do
    trac_init
    trac_config
    # create trac account for current user 
    set :trac_account, user
    set :trac_passwordfile_exists, false # hack - should check on remote system instead
    trac_user_add
    
    trac_create_pid_dir
  end
  
  task :trac_init, :roles => :scm do
    sudo "trac-admin #{trac_path} initenv #{application} sqlite:db/trac.db svn #{repos_root} /usr/local/share/trac/templates"
    trac_set_default_permissions 
  end
  
  task :trac_set_default_permissions, :roles => :scm do
    trac_anonymous_disable
    trac_authenticated_enable
  end
  
  # desc "disable anonymous access to everything"
  task :trac_anonymous_disable, :roles => :scm do
    sudo "trac-admin #{trac_path} permission remove anonymous '*'"
  end
  
  # desc "enable authenticated users access to everything"
  task :trac_authenticated_enable, :roles => :scm do
    sudo "trac-admin #{trac_path} permission add authenticated TRAC_ADMIN"
  end
  
  task :trac_config, :roles => :scm do
    deprec.render_template_to_file('trac.ini.erb', "#{trac_path}/conf/trac.ini")
  end
  
  task :trac_start, :roles => :scm do
    # XXX enable this for cap2
    # XXX run "echo point your browser to http://$CAPISTRANO:HOST$:#{tracd_port}/trac"  
    auth_string = "--auth=*,#{trac_password_file},#{application}"
    sudo "tracd #{auth_string} --daemonize --single-env --port=#{tracd_port} --pidfile=#{trac_pidfile} #{trac_path}"
  end
  
  task :trac_stop, :roles => :scm do
    sudo "kill `cat #{trac_pidfile}` >/dev/null 2>&1"
    sudo "rm -f #{trac_pidfile}"
  end
  
  desc "create a trac user"
  task :trac_user_add, :roles => :scm do
    create_file = trac_passwordfile_exists ? '' : ' -c '
    htdigest = '/usr/local/apache2/bin/htdigest'
    # XXX check if htdigest file exists and add '-c' option if not
    # sudo "test -f #{trac_path/conf/users.htdigest}
    create_file = trac_passwordfile_exists ? '' : ' -c '
    sudo_with_input("#{htdigest} #{create_file} #{trac_path}/conf/users.htdigest #{application} #{trac_account}", /password:/) 
  end
  
  desc "list trac users"
  task :trac_list_users, :roles => :scm do
    sudo "cat #{trac_path}/conf/users.htdigest"
  end
  

  
end