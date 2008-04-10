# Copyright 2006-2008 by Saulius Grigaitis. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :centos do
    namespace :postgresql do
      
      # Installation
      desc "Install postgresql"
      task :install, :roles => :db do
        install_deps
      end
      
      # Install dependencies for PostgreSQL 
      task :install_deps, :roles => :db do
        apt.install( {:base => %w(postgresql postgresql-server postgresql-devel)}, :stable, :repositories => [:centosplus] )
        gem2.install "ruby-pg"
      end

      desc "Create Database" 
      task :create_db, :roles => :db do
        #that's hack to initialize database (this should be replaced with initdb or so)
        start
        config_gen
        config
        restart
        read_config
        createuser(db_user, db_password)
        createdb(db_name, db_user)
      end
       
      #task :symlink_mysql_sockfile, :roles => :db do
        # rails puts "socket: /tmp/mysql.sock" into config/database.yml
        # this is not the location for our ubuntu's mysql socket file
        # so we create this link to make deployment using rails defaults simpler
      #  sudo "ln -sf /var/run/mysqld/mysqld.sock /tmp/mysql.sock"
      #end
      
      # Configuration
      
      SYSTEM_CONFIG_FILES[:postgresql] = [
        
        {:template => "pg_hba.conf.erb",
         :path => '/var/lib/pgsql/data/pg_hba.conf',
         :mode => 0644,
         :owner => 'root:root'}
      ]
      
      desc "Generate configuration file(s) for postgresql from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:postgresql].each do |file|
          deprec2.render_template(:postgresql, file)
        end
      end
      
      desc "Push postgresql config files to server"
      task :config, :roles => :db do
        deprec2.push_configs(:postgresql, SYSTEM_CONFIG_FILES[:postgresql])
      end
      
      task :activate, :roles => :db do
        send(run_method, "/sbin/chkconfig --add postgresql")
      end  
      
      task :deactivate, :roles => :db do
        send(run_method, "/sbin/chkconfig --del postgresql")
      end
      
      # Control
      
      desc "Start PostgreSQL"
      task :start, :roles => :db do
        send(run_method, "/etc/init.d/postgresql start")
      end
      
      desc "Stop PostgreSQL"
      task :stop, :roles => :db do
        send(run_method, "/etc/init.d/postgresql stop")
      end
      
      desc "Restart PostgreSQL"
      task :restart, :roles => :db do
        send(run_method, "/etc/init.d/postgresql restart")
      end
      
      desc "Reload PostgreSQL"
      task :reload, :roles => :db do
        send(run_method, "/etc/init.d/postgresql reload")
      end
     
            
      task :backup, :roles => :db do
      end
      
      task :restore, :roles => :db do
      end
            
    end
  end

  # Imported from Rails Machine gem

  def createdb(db, user)
    sudo "su - postgres -c \'createdb -O #{user} #{db}\'"  
  end
  
  def createuser(user, password)
    cmd = "su - postgres -c \'createuser -P -D -A -E #{user}\'"
    sudo cmd do |channel, stream, data|
      if data =~ /^Enter password for new/
        channel.send_data "#{password}\n" 
      end
      if data =~ /^Enter it again:/
        channel.send_data "#{password}\n" 
      end
      if data =~ /^Shall the new role be allowed to create more new roles?/
        channel.send_data "n\n" 
      end
    end
  end
  
  def command(sql, database)
    run "psql --command=\"#{sql}\" #{database}" 
  end

  def read_config
    db_config = YAML.load_file('config/database.yml')
    set :db_user, db_config[rails_env]["username"]
    set :db_password, db_config[rails_env]["password"] 
    set :db_name, db_config[rails_env]["database"]
  end

end
