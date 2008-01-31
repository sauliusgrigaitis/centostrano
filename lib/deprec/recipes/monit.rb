# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do namespace :monit do
        
  set :monit_user,  'monit'
  set :monit_group, 'monit'
    
  SRC_PACKAGES[:monit] = {
    :filename => 'monit-4.10.tar.gz',   
    :md5sum => "76ca10ba7a3da3736b8540edca16c70a  monit-4.10.tar.gz", 
    :dir => 'monit-4.10',  
    :url => "http://www.tildeslash.com/monit/dist/monit-4.10.tar.gz",
    :unpack => "tar zxf monit-4.10.tar.gz;",
    :configure => %w(
      ./configure
      ;
      ).reject{|arg| arg.match '#'}.join(' '),
    :make => 'make;',
    :install => 'make install;'
  }
  
  desc "Install monit"
  task :install do
    install_deps
    deprec2.download_src(SRC_PACKAGES[:monit], src_dir)
    deprec2.install_from_src(SRC_PACKAGES[:monit], src_dir)
    create_monit_user
  end
  
  # install dependencies for monit
  task :install_deps do
    apt.install( {:base => %w(flex bison)}, :stable )
  end
  
  task :create_nginx_user do
    deprec2.groupadd(nginx_group)
    deprec2.useradd(nginx_user, :group => nginx_group, :homedir => false)
  end
    
  SYSTEM_CONFIG_FILES[:nginx] = [
    
    {:template => 'nginx-init-script',
     :path => '/etc/init.d/nginx',
     :mode => '0755',
     :owner => 'root:root'},
     
    {:template => 'nginx.conf.erb',
     :path => "/usr/local/nginx/conf/nginx.conf",
     :mode => '0644',
     :owner => 'root:root'},
      
    {:template => 'mime.types.erb',
     :path => "/usr/local/nginx/conf/mime.types",
     :mode => '0644',
     :owner => 'root:root'}
  ]
  
  PROJECT_CONFIG_FILES[:nginx] = [
  ]
  
  desc <<-DESC
  Generate nginx config from template. Note that this does not
  push the config to the server, it merely generates required
  configuration files. These should be kept under source control.            
  The can be pushed to the server with the :config task.
  DESC
  task :config_gen do
    SYSTEM_CONFIG_FILES[:nginx].each do |file|
      deprec2.render_template(:nginx, file)
    end
  end
  
  # task :config_gen_project do
  #   PROJECT_CONFIG_FILES[:nginx].each do |file|
  #     render_template(:nginx, file)
  #   end
  # end
  
  desc "Push trac config files to server"
  task :config, :roles => :web do
    deprec2.push_configs(:nginx, SYSTEM_CONFIG_FILES[:nginx])
  end

  desc "Start Nginx"
  task :start, :roles => :web do
    send(run_method, "/etc/init.d/nginx start")
  end

  desc "Stop Nginx"
  task :stop, :roles => :web do
    send(run_method, "/etc/init.d/nginx stop")
  end

  desc "Restart Nginx"
  task :restart, :roles => :web do
    send(run_method, "/etc/init.d/nginx restart")
  end

  desc "Reload Nginx"
  task :reload, :roles => :web do
    send(run_method, "/etc/init.d/nginx reload")
  end
   
  desc <<-DESC
    Activate nginx start scripts on server.
    Setup server to start nginx on boot.
  DESC
  task :activate, :roles => :web do
    send(run_method, "update-rc.d nginx defaults")
  end
  
  desc <<-DESC
    Dectivate nginx start scripts on server.
    Setup server to start nginx on boot.
  DESC
  task :deactivate, :roles => :web do
    send(run_method, "update-rc.d -f nginx remove")
  end
  
  task :backup, :roles => :web do
    # there's nothing to backup for nginx
  end
  
  task :restore, :roles => :web do
    # there's nothing to store for nginx
  end

  end end
end