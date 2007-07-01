require 'yaml'
require 'capistrano'
require 'capistrano/cli'

module MySQLMethods
  
  def execute(sql, user)
    user = 'root'
    run "mysql --user=#{user} -p --execute=\"#{sql}\"" do |channel, stream, data|
      handle_mysql_password(user, channel, stream, data)
    end
  end
  
  def create_database(db_name, user = nil, pass = nil)
    sql = ["CREATE DATABASE IF NOT EXISTS #{db_name};"]
    sql << "GRANT ALL PRIVILEGES ON #{user}.* TO #{user}@localhost" if user
    sql << " IDENTIFIED BY '#{pass}'" if pass
    sql << ';'
    sql << 'flush privileges;'
    mysql.execute sql, mysql_admin
  end
  
  private
  def handle_mysql_password(user, channel, stream, data)
    logger.info data, "[database on #{channel[:host]} asked for password]"
    if data =~ /^Enter password:/
      pass = Capistrano::CLI.password_prompt "Enter database password for '#{user}':"
      channel.send_data "#{pass}\n" 
    end
  end
end

Capistrano.plugin :mysql, MySQLMethods

Capistrano.configuration(:must_exist).load do
  
  set :mysql_admin, nil
  
  desc "Execute MySQL statements using --execute option. Set the 'sql' variable."
  task :execute_mysql, :roles => :db, :only => { :primary => true } do
    set_mysql_admin
    mysql.execute sql, mysql_admin
  end
  
  desc "Create MySQL database and user based on config/database.yml"
  task :setup_mysql, :roles => :db, :only => { :primary => true } do
    # on_rollback {}
    
    # rails puts "socket: /tmp/mysql.sock" into config/database.yml
    # this is not the location for our ubuntu's mysql socket file
    # so we create this link to make depployment using rails defaults simpler
    sudo "sudo ln -sf /var/run/mysqld/mysqld.sock /tmp/mysql.sock"
    
    set_mysql_admin
    read_config
    
    sql = "CREATE DATABASE IF NOT EXISTS #{db_name};"
    sql += "GRANT ALL PRIVILEGES ON #{db_name}.* TO #{db_user}@localhost IDENTIFIED BY '#{db_password}';"  
    mysql.execute sql, mysql_admin
  end
  
  def read_config
    db_config = YAML.load_file('config/database.yml')
    set :db_user, db_config[rails_env]["username"]
    set :db_password, db_config[rails_env]["password"] 
    set :db_name, db_config[rails_env]["database"]
  end
  
  def set_mysql_admin
    set :mysql_admin, user unless mysql_admin
  end
  
end
