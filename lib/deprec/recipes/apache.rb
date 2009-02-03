# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :centos do
    namespace :apache do
      
      SRC_PACKAGES[:apache] = {
        :filename => 'httpd-2.2.11.tar.gz',   
        :md5sum => "03e0a99a5de0f3f568a0087fb9993af9 httpd-2.2.11.tar.gz", 
        :dir => 'httpd-2.2.11',  
        :url => "http://www.apache.org/dist/httpd/httpd-2.2.11.tar.gz",
        :unpack => "tar zxf httpd-2.2.11.tar.gz;",
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
        :install => '--fstrans=no make install;',
        :post_install => 'install -b support/apachectl /etc/init.d/httpd;',
        :version => 'c2.2.11',
        :release => '1'
      }

      desc "Install apache"
      task :install do
        install_deps
        sudo "yum remove -y httpd"
        deprec2.download_src(SRC_PACKAGES[:apache], src_dir)
        yum.install_from_src(SRC_PACKAGES[:apache], src_dir)
        #enable_mod_rewrite
      end
      
      # install dependencies for apache
      task :install_deps do
        apt.install( {:base => %w(zlib1g-dev zlib1g openssl openssl-devel)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:apache] = [
        # They're generated and put in place during install
        # I may put them in here at some point
      ]

      PROJECT_CONFIG_FILES[:apache] = [
        # Not required
      ]

      desc "Generate configuration file(s) for apache from template(s)"
      task :config_gen do
        config_gen_system
      end

      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:apache].each do |file|
          deprec2.render_template(:apache, file)
        end
      end

      task :config_gen_project do
        PROJECT_CONFIG_FILES[:apache].each do |file|
          deprec2.render_template(:apache, file)
        end
      end
      
      desc "Push apache config files to server"
      task :config, :roles => :web do
        deprec2.push_configs(:apache, SYSTEM_CONFIG_FILES[:apache])
      end

      # Stub so generic tasks don't fail (e.g. centos:web:config_project)
      task :config_project, :roles => :web do
      end

      task :enable_mod_rewrite, :roles => :web do
        #sudo "a2enmod rewrite"
      end


      desc "Start Apache"
      task :start, :roles => :web do
        send(run_method, "/etc/init.d/httpd start")
      end

      desc "Stop Apache"
      task :stop, :roles => :web do
        send(run_method, "/etc/init.d/httpd stop")
      end

      desc "Restart Apache"
      task :restart, :roles => :web do
        send(run_method, "/etc/init.d/httpd restart")
      end

      desc "Reload Apache"
      task :reload, :roles => :web do
        send(run_method, "/etc/init.d/httpd reload")
      end

      desc "Set apache to start on boot"
      task :activate do
        send(run_method, "sed -i '2i# chkconfig: 2345 10 90' /etc/init.d/httpd")
        send(run_method, "sed -i '3i# description: Activates/Deactivates Apache Web Server' /etc/init.d/httpd")
        send(run_method, "/sbin/chkconfig --add httpd")
        send(run_method, "/sbin/chkconfig --level 345 httpd on")
      end
      
      desc "Set apache to not start on boot"
      task :deactivate, :roles => :web do
        send(run_method, "/sbin/chkconfig --del httpd")
      end
      
      task :backup, :roles => :web do
        # not yet implemented
      end
      
      task :restore, :roles => :web do
        # not yet implemented
      end

      # Generate an index.html page  
      task :install_index_page do
        deprec2.mkdir(apache_docroot, :owner => :root, :group => :deploy, :mode => 0775, :via => :sudo)
        std.su_put deprec2.render_template(:apache, :template => 'index.html.erb'), File.join('/var/www/index.html')
        std.su_put deprec2.render_template(:apache, :template => 'master.css'), File.join('/var/www/master.css')
      end
      
    end
  end
end
