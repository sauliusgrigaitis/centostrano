Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :nagios do
      
      SRC_PACKAGES[:nagios] = {
        :filename => 'httpd-2.2.6.tar.gz',   
        :md5sum => "d050a49bd7532ec21c6bb593b3473a5d  httpd-2.2.6.tar.gz", 
        :dir => 'httpd-2.2.6',  
        :url => "http://www.apache.org/dist/httpd/httpd-2.2.6.tar.gz",
        :unpack => "tar zxf httpd-2.2.6.tar.gz;",
        :configure => %w(
          ./configure
          --enable-mods-shared=all
          --enable-proxy 
          --enable-proxy-balancer 
          --enable-proxy-http 
          --enable-rewrite  
          --enable-cache 
          --enable-headers 
          --enable-ssl 
          --enable-deflate 
          --with-included-apr   #_so_this_recipe_doesn't_break_when_rerun
          --enable-dav          #_for_subversion_
          --enable-so           #_for_subversion_
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;',
        :post_install => 'install -b support/apachectl /etc/init.d/httpd;'
      }
      
      desc "Install nagios"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:nagios], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:nagios], src_dir)
        setup_vhost_dir
        install_index_page
      end
         
      # install dependencies for nagios
      task :install_deps do
        puts "This function should be overridden by your OS plugin!"
        apt.install( {:base => %w(build-essential zlib1g-dev zlib1g openssl libssl-dev)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:nagios] = [
        
        {:template => 'nagios.cfg.erb',
        :path => '/usr/local/nagios/etc/nagios.cfg',
        :mode => '0664',
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
        :owner => 'nagios:nagios'}
        
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

      desc "Set apache to start on boot"
      task :activate, :roles => :web do
        send(run_method, "update-rc.d httpd defaults")
      end
      
      desc "Set apache to not start on boot"
      task :deactivate, :roles => :web do
        send(run_method, "update-rc.d -f httpd remove")
      end
      
      task :backup, :roles => :web do
        # not yet implemented
      end
      
      task :restore, :roles => :web do
        # not yet implemented
      end
    
    end
  end
end