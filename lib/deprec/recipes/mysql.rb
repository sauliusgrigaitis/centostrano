Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :mysql do
      
      desc "Install mysql"
      task :install, :roles => :db do
      end
      
      desc "Generate configuration file(s) for XXX from template(s)"
      task :config_gen, :roles => :db do
      end
      
      desc 'Deploy configuration files(s) for XXX' 
      task :config, :roles => :db do
      end
      
      task :start, :roles => :db do
      end
      
      task :stop, :roles => :db do
      end
      
      task :restart, :roles => :db do
      end
      
      task :activate, :roles => :db do
      end  
      
      task :deactivate, :roles => :db do
      end
      
      task :backup, :roles => :db do
      end
      
      task :restore, :roles => :db do
      end
      
      task :setup, :roles => :db do
        # rails puts "socket: /tmp/mysql.sock" into config/database.yml
        # this is not the location for our ubuntu's mysql socket file
        # so we create this link to make depployment using rails defaults simpler
        sudo "sudo ln -sf /var/run/mysqld/mysqld.sock /tmp/mysql.sock"
        # run "rake db:create" # waiting for Rails2
      end
      
    end
  end
end