require 'deprec/recipes/ssh'
require 'deprec/recipes/svn'
require 'deprec/recipes/ubuntu'
require 'deprec/third_party/mongrel_cluster/recipes'
require 'deprec/third_party/vmbuilder/plugins'
require 'deprec/third_party/railsmachine/recipes/svn'
require 'deprec/third_party/railsmachine/recipes/apache'
require 'deprec/third_party/railsmachine/recipes/mysql'
require 'deprec/capistrano_extensions/deprec_extensions.rb'
require 'deprec/capistrano_extensions/actor_extensions.rb'

Capistrano.configuration(:must_exist).load do
  set :user, (defined?(user) ? user : ENV['USER']) # user who is deploying
  set :group, 'deploy'           # deployment group
  set :src_dir, (defined?(src_dir) ? src_dir : '/usr/local/src') # 3rd party src on servers 
  set :app_symlinks, nil                  
  
  desc <<-DESC
  setup_rails_host takes a stock standard ubuntu 'dapper' 6.06.1 server
  and installs everything needed to be a rails machine
  DESC
  task :install_rails_stack do
    setup_user_perms
    enable_universe # we'll need some packages from the 'universe' repository
    disable_cdrom_install # we don't want to have to insert cdrom
    install_packages_for_rails # install packages that come with distribution
    install_rubygems
    install_gems 
    install_apache
  end
  
  desc "Set up the expected application directory structure on all boxes"
  task :setup, :except => { :no_release => true } do
    setup_paths
    run <<-CMD
      mkdir -p -m 775 #{releases_path} #{shared_path}/system &&
      mkdir -p -m 777 #{shared_path}/log &&
      mkdir -p -m 777 #{shared_path}/pids
    CMD
    setup_servers
  end
  
  desc "setup and configure servers"
  task :setup_servers do
    setup_web
    setup_paths
    setup_app
    setup_symlinks
    setup_db
  end
  
  desc "Setup web server."
  task :setup_web, :roles => :web  do
    set :apache_server_name, domain unless apache_server_name
    setup_apache
    configure_apache
  end
  
  desc "Setup application server."
  task :setup_app, :roles => :app  do
    set :mongrel_environment, rails_env
    set :mongrel_port, apache_proxy_port
    set :mongrel_servers, apache_proxy_servers
    install_mongrel_start_script
    setup_mongrel_cluster_path
    configure_mongrel_cluster
  end
  
  desc "Restart application server."
  task :restart_app, :roles => :app  do
    restart_mongrel_cluster
  end
  
  desc "Start application server."
  task :start_app, :roles => :app  do
    start_mongrel_cluster
  end

  desc "Start the processes on the application server by calling start_app."
  task :spinner, :roles => :app do
    start_app
  end
  
  desc "Setup public symlink directories"
  task :setup_symlinks, :roles => [:app, :web] do
    if app_symlinks
      app_symlinks.each { |link| run "mkdir -p #{shared_path}/public/#{link}" }
    end
  end
  
  desc "Setup database server."
  task :setup_db, :roles => :db, :only => { :primary => true } do
    setup_mysql
  end
  
  desc "Setup source control server."
  task :setup_scm, :roles => :scm  do
    setup_svn
    import_svn
  end
  
  desc "setup extra paths required for deployment"
  task :setup_paths, :roles => :app do
    # XXX make a function to create a group writable dir
    sudo "test -d #{shared_path}/config || sudo mkdir -p #{shared_path}/config"
    sudo "chgrp -R #{group} #{deploy_to}"
    sudo "chmod -R g+w #{deploy_to}"
  end
  
  task :create_user do
    newuser=user
    user='root'
    # run "useradd -m #{newuser}"
    run "ls"
    user=newuser
  end
  
  task :install_gems do
    gem.install 'rails'                 # gem lib makes installing gems fun
    gem.select 'mongrel'                # mongrel requires we select a version
    gem.install 'mongrel_cluster'
  end
  
  desc "create deployment group and add current user to it"
  task :setup_user_perms do
    sudo "grep '#{group}:' /etc/group || sudo groupadd #{group}"
    sudo "groups #{user} | grep ' #{group} ' || sudo usermod --groups #{group} -a #{user}"
  end
  
  task :install_rubygems do
    # ??? is this an OK way to pass values around to the functions?
    version = 'rubygems-0.9.0'
    set :file_to_get, {
      :file => version + '.tgz',
      :dir => version,
      :url => "http://rubyforge.org/frs/download.php/11289/#{version}.tgz",
      :unpack => "tar zxf #{version}.tgz;",
      :install => '/usr/bin/ruby1.8 setup.rb;'
    }
    download_src
    install_from_src
    gem.update_system
  end
  
  task :install_apache do
    # ??? is this an OK way to pass values around to the functions?
    version = 'httpd-2.2.3'
    set :file_to_get, {
      :file => version + '.tar.gz',    
      :dir => version,  
      :url => "http://www.apache.org/dist/httpd/#{version}.tar.gz",
      :unpack => "tar zxf #{version}.tar.gz;",
      :configure => './configure --enable-proxy --enable-proxy-balancer --enable-proxy-http --enable-rewrite  --enable-cache --enable-headers --enable-ssl --enable-deflate;',
      :make => 'make;',
      :install => 'make install;',
      :post_install => 'cp support/apachectl /etc/init.d/httpd && chmod 0777 /etc/init.d/httpd;'
      # XXX use 'install' command instead
    }
    download_src
    install_from_src
  end

  # XXX move into cap extensions
  desc "install package from source"
  task :install_from_src do
    package_dir = File.join(src_dir, file_to_get[:dir])
    unpack_src
    # XXX we need run_sh and sudo_sh functions to make 'cd' cmd work
    sudo <<-SUDO
    sh -c '
      cd #{package_dir};
      #{file_to_get[:configure]}
      #{file_to_get[:make]}
      #{file_to_get[:install]}
      #{file_to_get[:post_install]}
      '
    SUDO
  end
  
  desc "unpack src and make it writable by the group"
  task :unpack_src do
    package_dir = File.join(src_dir, file_to_get[:dir])
    sudo <<-SUDO
    sh -c '
      cd #{src_dir};
      test -d #{package_dir}.old && rm -fr #{package_dir}.old;
      test -d #{package_dir} && mv #{package_dir} #{package_dir}.old;
      #{file_to_get[:unpack]}
      chgrp -R #{group} #{package_dir};  
      chmod -R g+w #{package_dir};
    '
    SUDO
  end
  
  desc "Setup public symlink directories"
  task :setup_symlinks, :roles => [:app, :web] do
   if app_symlinks
     app_symlinks.each { |link| run "mkdir -p #{shared_path}/public/#{link}" }
   end
  end

  desc "Link up any public directories."
  task :symlink_public, :roles => [:app, :web] do
   if app_symlinks
     app_symlinks.each { |link| run "ln -nfs #{shared_path}/public/#{link} #{current_path}/public/#{link}" }
   end
  end
  
  desc "install the rmagic gem, and dependent image-magick library"
  task :install_rmagick, :roles => [:app, :web] do
    install_image_magic
    gem.install 'rmagick'
  end
  
  # Craig: I've kept this generic rather than calling the task setup postfix. 
  # if people want other smtp servers, it could be configurable
  desc "install and configure postfix"
  task :setup_smtp_server do
    install_postfix
    deprec.render_template_to_file('postfix_main', '/etc/postfix/main.cf')
  end
    
  # something for later...
  # desc "render a template"
  # task :z_template do
  #   file = File.join(File.dirname(__FILE__), 'recipes', 'templates', 'test_goo.rhtml')
  #   msg = render :template => File.read(file), :foo => 'good', :bar => 'night'
  #   run "echo #{msg}"
  # end
  
  "will be moved to capistrano extension"
  task :download_src do
    # move this into cap extension
    # XXX should make this group writable
    # XXX so we don't need to sudo to compile
    sudo "test -d #{src_dir} || sudo mkdir #{src_dir}" 
    sudo "chgrp -R #{group} #{src_dir}"
    sudo "chmod -R g+w #{src_dir}"
    sudo "sh -c 'cd #{src_dir} && test -f #{file_to_get[:file]} || wget #{file_to_get[:url]}'"
  end
  
end
