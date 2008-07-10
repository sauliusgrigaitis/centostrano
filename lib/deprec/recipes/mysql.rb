# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :centos do
    namespace :mysql do
      
      # Installation
      
      desc "Install mysql"
      task :install, :roles => :db do
        install_deps
        symlink_mysql_sockfile # XXX still needed?
      end
      
      # Install dependencies for Mysql
      task :install_deps, :roles => :db do
        apt.install( {:base => %w(mysql mysql-server mysql-devel)}, :stable )
      end
      
      desc "Create Database" 
      task :create_db, :roles => :db do
        read_config
        sql = "CREATE DATABASE #{db_name}; GRANT ALL PRIVILEGES ON #{db_name}.* TO #{db_user}@localhost IDENTIFIED BY '#{db_password}';"  
        execute(sql, db_user)
      end
       
      task :symlink_mysql_sockfile, :roles => :db do
        # rails puts "socket: /tmp/mysql.sock" into config/database.yml
        # this is not the location for our ubuntu's mysql socket file
        # so we create this link to make deployment using rails defaults simpler
        sudo "ln -sf /var/run/mysqld/mysqld.sock /tmp/mysql.sock"
      end
      
      # Configuration
      
      SYSTEM_CONFIG_FILES[:mysql] = [
        
        {:template => "my.cnf.erb",
         :path => '/etc/mysql/my.cnf',
         :mode => 0644,
         :owner => 'root:root'}
      ]
      
      desc "Generate configuration file(s) for mysql from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:mysql].each do |file|
          deprec2.render_template(:mysql, file)
        end
      end
      
      desc "Push trac config files to server"
      task :config, :roles => :db do
        deprec2.push_configs(:mysql, SYSTEM_CONFIG_FILES[:mysql])
      end
      
      task :activate, :roles => :db do
        send(run_method, "/sbin/chkconfig --add mysqld")
        send(run_method, "/sbin/chkconfig mysqld on")
      end  
      
      task :deactivate, :roles => :db do
        send(run_method, "/sbin/chkconfig --del mysqld")
      end
      
      # Control
      
      desc "Start Mysql"
      task :start, :roles => :db do
        send(run_method, "/etc/init.d/mysqld start")
      end
      
      desc "Stop Mysql"
      task :stop, :roles => :db do
        send(run_method, "/etc/init.d/mysqld stop")
      end
      
      desc "Restart Mysql"
      task :restart, :roles => :db do
        send(run_method, "/etc/init.d/mysqld restart")
      end
      
      desc "Reload Mysql"
      task :reload, :roles => :db do
        send(run_method, "/etc/init.d/mysqld reload")
      end
      
      
      task :backup, :roles => :db do
      end
      
      task :restore, :roles => :db do
      end
            
    end
  end
 
# Imported from Rails Machine gem (Copyright (c) 2006 Bradley Taylor, bradley@railsmachine.com)

  def execute(sql, user)
    run "mysql --user=root --execute=\"#{sql}\"" do |channel, stream, data|
      handle_mysql_password(user, channel, stream, data)
    end
  end
  
  def handle_mysql_password(user, channel, stream, data)
    logger.info data, "[database on #{channel[:host]} asked for password]"
    if data =~ /^Enter password:/
      pass = Capistrano::CLI.password_prompt "Enter database password for '#{user}':"
      channel.send_data "#{pass}\n" 
    end
  end

end

#
# Setup replication
#

# setup user for repl
# GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%.yourdomain.com' IDENTIFIED BY 'slavepass';

# get current position of binlog
# mysql> FLUSH TABLES WITH READ LOCK;
# Query OK, 0 rows affected (0.00 sec)
# 
# mysql> SHOW MASTER STATUS;
# +------------------+----------+--------------+------------------+
# | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
# +------------------+----------+--------------+------------------+
# | mysql-bin.000012 |      296 |              |                  | 
# +------------------+----------+--------------+------------------+
# 1 row in set (0.00 sec)
# 
# # get current data
# mysqldump --all-databases --master-data >dbdump.db
# 
# UNLOCK TABLES;


# Replication Features and Issues
# http://dev.mysql.com/doc/refman/5.0/en/replication-features.html
