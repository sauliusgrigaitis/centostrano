Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do namespace :nginx do
        
  set :nginx_server_name, nil
  
  desc "Install nginx on server"
  task :install, :roles => :web do
  end
  
  desc "Remove nginx from server"
  task :uninstall, :roles => :web do
  end
  
  desc <<-DESC
  Generate nginx config from template. Note that this does not
  push the config to the server, it merely generates required
  configuration files. These should be kept under source control.            
  The can be pushed to the server with the :config task.
  DESC
  task :config_gen do
    # generate config from template
  end
  
  desc "Push nginx config to server"
  task :config, :roles => :web do
    # if config does not exist, :config_gen
    # push config to server
  end
  
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