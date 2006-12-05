require 'yaml'
require 'capistrano'
require 'capistrano/cli'

module MySQLMethods
  
  def execute(sql, user)
    run "mysql --user=root -p --execute=\"#{sql}\"" do |channel, stream, data|
      handle_mysql_password(user, channel, stream, data)
    end
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
    
    set_mysql_admin
    read_config
    
    sql = "CREATE DATABASE #{db_name};"
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
