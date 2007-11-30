Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do namespace :nginx do
        
  set :nginx_server_name, nil
  
  # Configuration summary
  #   + threads are not used
  #   + using system PCRE library
  #   + OpenSSL library is not used
  #   + md5 library is not used
  #   + sha1 library is not used
  #   + using system zlib library
  # 
  #   nginx path prefix: "/usr/local/nginx"
  #   nginx binary file: "/usr/local/nginx/sbin/nginx"
  #   nginx configuration file: "/usr/local/nginx/conf/nginx.conf"
  #   nginx pid file: "/usr/local/nginx/logs/nginx.pid"
  #   nginx error log file: "/usr/local/nginx/logs/error.log"
  #   nginx http access log file: "/usr/local/nginx/logs/access.log"
  #   nginx http client request body temporary files: "/usr/local/nginx/client_body_temp"
  #   nginx http proxy temporary files: "/usr/local/nginx/proxy_temp"
  #   nginx http fastcgi temporary files: "/usr/local/nginx/fastcgi_temp"
    
  
  # http://sysoev.ru/nginx/nginx-0.5.33.tar.gz
  desc "Install nginx"
  task :install do
    version = 'nginx-0.5.33'
    set :src_package, {
      :file => version + '.tar.gz',   
      :md5sum => "a78be74b4fd8e009545ef02488fcac86  #{version}.tar.gz", 
      :dir => version,  
      :url => "http://sysoev.ru/nginx/#{version}.tar.gz",
      :unpack => "tar zxf #{version}.tar.gz;",
      :configure => %w(
        ./configure
        --with-http_ssl_module
        --with-http_dav_module
        ;
        ).reject{|arg| arg.match '#'}.join(' '),
      :make => 'make;',
      :install => 'make install;',
      :post_install => ''
    }
    install_deps
    deprec2.download_src(src_package, src_dir)
    deprec2.install_from_src(src_package, src_dir)
  end
  
  # install dependencies for apache
  task :install_deps do
    puts "This function should be overridden by your OS plugin!"
    apt.install( {:base => %w(build-essential zlib1g-dev zlib1g openssl libssl-dev libpcre3-dev libgcrypt11-dev)}, :stable )
  end
    
  SYSTEM_CONFIG_FILES[:nginx] = [
    
    {:template => 'nginx-init-gutsy',
     :path => '/etc/init.d/nginx',
     :mode => '0755',
     :owner => 'root:root'},
     
     {:template => 'nginx.conf-gutsy.erb',
      :path => "/usr/local/nginx/conf/nginx.conf",
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
  task :config_gen, :roles => :scm do
    config_gen_system
    # config_gen_project
  end
  
  task :config_gen_system, :roles => :web do
    SYSTEM_CONFIG_FILES[:nginx].each do |file|
      render_template(:nginx, file)
    end
  end
  
  # task :config_gen_project, :roles => :web do
  #   PROJECT_CONFIG_FILES[:nginx].each do |file|
  #     render_template(:nginx, file)
  #   end
  # end
  
  desc "Push trac config files to server"
  task :config, :roles => :web do
    config_system
    # config_project
  end
  
  task :config_system, :roles => :web do
    deprec2.push_configs(:nginx, SYSTEM_CONFIG_FILES[:nginx])
  end
  
  # task :config_project, :roles => :web do
  #   deprec2.push_configs(:nginx, PROJECT_CONFIG_FILES[:nginx])
  # end
    
  desc "Start Nginx"
  task :start, :roles => :web do
    puts "starting nginx"
  end
  
  desc "Stop Nginx"
  task :stop, :roles => :web do
    puts "stopping nginx"
  end
  
  desc "Restart Nginx"
  task :restart, :roles => :web do
    stop
    start
  end
  
  desc <<-DESC
    Activate nginx start scripts on server.
    Setup server to start nginx on boot.
  DESC
  task :activate, :roles => :web do
  end
  
  desc <<-DESC
    Dectivate nginx start scripts on server.
    Setup server to start nginx on boot.
  DESC
  task :deactivate, :roles => :web do
  end
  
  task :backup, :roles => :web do
    # there's nothing to backup for nginx
  end
  
  task :restore, :roles => :web do
    # there's nothing to store for nginx
  end

  end end
end