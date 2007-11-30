Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :mysql do
      
      # Configuration parameters
      set :mysql_init_script, '/etc/init.d/mysql'
      
      
      # Installation
      
      desc "Install mysql"
      task :install, :roles => :db do
        install_deps
        apt.install( {:base => %w(build-essential mysql-server mysql-client)}, :stable )
        symlink_mysql_sockfile
      end
      
      task :symlink_mysql_sockfile, :roles => :db do
        # rails puts "socket: /tmp/mysql.sock" into config/database.yml
        # this is not the location for our ubuntu's mysql socket file
        # so we create this link to make deployment using rails defaults simpler
        sudo "ln -sf /var/run/mysqld/mysqld.sock /tmp/mysql.sock"
      end
      
      desc "Install dependencies for Mysql"
      task :install_deps, :roles => :db do
        apt.install( {:base => %w(mysql-server mysql-client)}, :stable )
      end
      
      
      # Configuration
      
      desc "Generate configuration file(s) for mysql from template(s)"
      task :config_gen, :roles => :db do
      end
      
      desc 'Deploy configuration files(s) for mysql' 
      task :config, :roles => :db do
      end
      
      task :activate, :roles => :db do
      end  
      
      task :deactivate, :roles => :db do
      end
      
      
      # Control
            
      task :start, :roles => :db do
        send(run_method, "#{mysql_init_script} start")
      end
      
      task :stop, :roles => :db do
        send(run_method, "#{mysql_init_script} stop")
      end
      
      task :restart, :roles => :db do
        send(run_method, "#{mysql_init_script} restart")
      end
      
      task :reload, :roles => :db do
        send(run_method, "#{mysql_init_script} reload")
      end
      
      
      task :backup, :roles => :db do
      end
      
      task :restore, :roles => :db do
      end
      
    end
  end
end