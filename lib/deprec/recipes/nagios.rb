Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :nagios do
      
      set :nagios_user, 'nagios'
      set :nagios_group, 'nagios'
      set :nagios_cmd_group, 'nagcmd' # Allow external commands to be submitted through the web interface
      
      SRC_PACKAGES[:nagios] = {
        :filename => 'nagios-3.0b7.tar.gz',   
        :md5sum => "3c3aaeddff040ba57c3c43553524b13f  nagios-3.0b7.tar.gz", 
        :dir => 'nagios-3.0b7',  
        :url => "http://osdn.dl.sourceforge.net/sourceforge/nagios/nagios-3.0b7.tar.gz",
        :unpack => "tar zxfv nagios-3.0b7.tar.gz;",
        :configure => %w(
          ./configure 
          --with-command-group=nagcmd
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make all;',
        :install => 'make install install-init install-commandmode'
      }
      
      desc "Install nagios"
      task :install do
        install_deps
        deprec2.groupadd(nagios_group)
        deprec2.useradd(nagios_user, :group => nagios_group, :homedir => false)
        deprec2.groupadd(nagios_cmd_group)
        deprec2.add_user_to_group(nagios, nagios_cmd_group)
        deprec2.add_user_to_group(nagios, apache_user)
        deprec2.mkdir('/usr/local/nagios/etc', :owner => "#{nagios_user}.#{nagios_group}", :via => :sudo)
        deprec2.mkdir('/usr/local/nagios/objects', :owner => "#{nagios_user}.#{nagios_group}", :via => :sudo)
        deprec2.download_src(SRC_PACKAGES[:nagios], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:nagios], src_dir)
      end
         
      # Install dependencies for nagios
      task :install_deps do
        apt.install( {:base => %w(build-essential)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:nagios] = [
        
        {:template => 'nagios.cfg.erb',
        :path => '/usr/local/nagios/etc/nagios.cfg',
        :mode => '0664',
        :owner => 'nagios:nagios'},

        {:template => 'resource.cfg.erb',
        :path => '/usr/local/nagios/etc/resource.cfg',
        :mode => '0660',
        :owner => 'nagios:nagios'},
        
        {:template => 'cgi.cfg.erb',
        :path => '/usr/local/nagios/etc/cgi.cfg',
        :mode => '0664',
        :owner => 'nagios:nagios'},

        {:template => 'htpasswd.users',
        :path => '/usr/local/nagios/etc/htpasswd.users',
        :mode => '0664',
        :owner => 'nagios:nagios'},

        {:template => 'templates.cfg.erb',
        :path => '/usr/local/nagios/etc/objects/templates.cfg',
        :mode => '0664',
        :owner => 'nagios:nagios'},
        
        {:template => 'commands.cfg.erb',
        :path => '/usr/local/nagios/etc/objects/commands.cfg',
        :mode => '0664',
        :owner => 'nagios:nagios'},
        
        {:template => 'timeperiods.cfg.erb',
        :path => '/usr/local/nagios/etc/objects/timeperiods.cfg',
        :mode => '0664',
        :owner => 'nagios:nagios'},
        
        {:template => 'localhost.cfg.erb',
        :path => '/usr/local/nagios/etc/objects/localhost.cfg',
        :mode => '0664',
        :owner => 'nagios:nagios'},
        
        {:template => 'contacts.cfg.erb',
        :path => '/usr/local/nagios/etc/objects/contacts.cfg',
        :mode => '0664',
        :owner => 'nagios:nagios'},
        
        {:template => 'hosts.cfg.erb',
        :path => '/usr/local/nagios/etc/objects/hosts.cfg',
        :mode => '0664',
        :owner => 'nagios:nagios'},
        
        {:template => 'nagios_apache_vhost.conf.erb',
         :path => "conf/nagios_apache_vhost.conf",
         :mode => '0644',
         :owner => 'root:root'}
      
      ]

      PROJECT_CONFIG_FILES[:nagios] = [

      ]

      desc "Generate configuration file(s) for nagios from template(s)"
      task :config_gen do
        config_gen_system
        config_gen_project
      end

      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:nagios].each do |file|
          deprec2.render_template(:nagios, file)
        end
      end

      task :config_gen_project do
        PROJECT_CONFIG_FILES[:nagios].each do |file|
          deprec2.render_template(:nagios, file)
        end
      end
      
      desc "Push nagios config files to server"
      task :config, :roles => :nagios do
        config_system
        config_project
      end

      task :config_system, :roles => :nagios do
        deprec2.push_configs(:nagios, SYSTEM_CONFIG_FILES[:nagios])
      end

      task :config_project, :roles => :nagios do
        deprec2.push_configs(:nagios, PROJECT_CONFIG_FILES[:nagios])
      end

      desc "Start Nagios"
      task :start, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios start")
      end

      desc "Stop Nagios"
      task :stop, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios stop")
      end

      desc "Restart Nagios"
      task :restart, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios restart")
      end

      desc "Reload Nagios"
      task :reload, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios reload")
      end
      
      desc "Run Nagios config check"
      task :config_check, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios check")
      end

      desc "Set Nagios to start on boot"
      task :activate, :roles => :web do
        send(run_method, "update-rc.d nagios defaults")
      end
      
      desc "Set Nagios to not start on boot"
      task :deactivate, :roles => :web do
        send(run_method, "update-rc.d -f nagios remove")
      end
      
      task :backup, :roles => :web do
        # not yet implemented
      end
      
      task :restore, :roles => :web do
        # not yet implemented
      end
      
      #
      # Service specific tasks
      #
      
      # XXX quick and dirty - clean up later
      desc "Grant a user access to the web interface"
      task :htpass, :roles => :nagios do
        target_user = Capistrano::CLI.ui.ask "Userid" do |q|
          q.default = 'nagiosadmin'
        end
        system "htpasswd config/nagios/usr/local/nagios/etc/htpasswd.users #{target_user}"
      end
    
    end
    
    
    SRC_PACKAGES[:nagios_plugins] = {
      :filename => 'nagios-plugins-1.4.10.tar.gz',   
      :md5sum => "c67841223864ae1626ab2adb2f0b4c9d  nagios-plugins-1.4.10.tar.gz", 
      :dir => 'nagios-plugins-1.4.10',  
      :url => "wget http://osdn.dl.sourceforge.net/sourceforge/nagiosplug/nagios-plugins-1.4.10.tar.gz",
      :unpack => "tar zxfv nagios-plugins-1.4.10.tar.gz;",
      :configure => "./configure --with-nagios-user=#{nagios_user} --with-nagios-group=#{nagios_group};",
      :make => 'make;',
      :install => 'make install;'
    }   
          
    namespace :nagios_plugins do
    
      task :install do
        deprec2.download_src(SRC_PACKAGES[:nagios_plugins], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:nagios_plugins], src_dir)        
      end
      
    end
    
  end
end