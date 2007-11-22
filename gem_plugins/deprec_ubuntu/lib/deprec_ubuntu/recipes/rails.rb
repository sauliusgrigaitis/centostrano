Capistrano.configuration(:must_exist).load do
  
  set :domain, { Capistrano::CLI.ui.ask "enter URL for trac" }
  
  set :database_yml_in_scm, true

  # database.yml stuff
  #
  # XXX DRY this up 
  # I don't know how to let :gen_db_yml check if values have been set.
  #
  # if (self.respond_to?("db_host_#{rails_env}".to_sym)) # doesn't seem to work
  
  set :db_host_default, lambda { Capistrano::CLI.prompt 'Enter database host', 'localhost'}
  set :db_host_staging, lambda { db_host_default }
  set :db_host_production, lambda { db_host_default }
  
  set :db_name_default, lambda { Capistrano::CLI.prompt 'Enter database name', "#{application}_#{rails_env}" }
  set :db_name_staging, lambda { db_name_default }
  set :db_name_production, lambda { db_name_default }
  
  set :db_user_default, lambda { Capistrano::CLI.prompt 'Enter database user', 'root' }
  set :db_user_staging, lambda { db_user_default }
  set :db_user_production, lambda { db_user_default }
  
  set :db_pass_default, lambda { Capistrano::CLI.prompt 'Enter database pass', '' }
  set :db_pass_staging, lambda { db_pass_default }
  set :db_pass_production, lambda { db_pass_default }
  
  set :db_adaptor_default, lambda { Capistrano::CLI.prompt 'Enter database adaptor', 'mysql' }
  set :db_adaptor_staging, lambda { db_adaptor_default }
  set :db_adaptor_production, lambda { db_adaptor_default }
  
  set :db_socket_default, lambda { Capistrano::CLI.prompt('Enter database socket', '')}
  set :db_socket_staging, lambda { db_socket_default }
  set :db_socket_production, lambda { db_socket_default }


  task :generate_database_yml, :roles => :app do    
    database_configuration = render :template => <<-EOF
#{rails_env}:
  adapter: #{self.send("db_adaptor_#{rails_env}")}
  database: #{self.send("db_name_#{rails_env}")}
  username: #{self.send("db_user_#{rails_env}")}
  password: #{self.send("db_pass_#{rails_env}")}
  host: #{self.send("db_host_#{rails_env}")}
  socket: #{self.send("db_socket_#{rails_env}")}
EOF
    run "mkdir -p #{deploy_to}/#{shared_dir}/config" 
    put database_configuration, "#{deploy_to}/#{shared_dir}/config/database.yml" 
  end
  
  task :after_update_code, :roles => :app do
    symlink_database_yml unless database_yml_in_scm
  end
  
  desc "Link in the production database.yml" 
  task :symlink_database_yml, :roles => :app do
    # run "rm -f #{current_path}/config/database.yml"
    run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml" 
  end
  
end