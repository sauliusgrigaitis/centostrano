Capistrano::Configuration.instance(:must_exist).load do 
    
  set :database_yml_in_scm, true
  set :app_symlinks, nil
  
  namespace :deprec do
    namespace :rails do
      
      desc "Setup application server."
      task :setup_app, :roles => :app  do
        set :mongrel_environment, rails_env
        set :mongrel_port, apache_proxy_port
        set :mongrel_servers, apache_proxy_servers
        create_mongrel_user_and_group
        install_mongrel_start_script
        setup_mongrel_cluster_path
        configure_mongrel_cluster
      end
      
      desc "Start the processes on the application server by calling start_app."
      task :spinner, :roles => :app do
        start_app
      end
      
      desc "Setup database server."
      task :setup_db, :roles => :db, :only => { :primary => true } do
        setup_mysql
      end

      desc "Setup source control server."
      task :setup_scm, :roles => :scm  do
        svn_create_repos
        svn_import
      end

      task :install_gems do
        gem.install 'rails'                 # gem lib makes installing gems fun
        gem.select 'mongrel'                # mongrel requires we select a version
        gem.install 'mongrel_cluster'
        gem.install 'builder'
      end

      desc "install the rmagic gem, and dependent image-magick library"
      task :install_rmagick, :roles => [:app, :web] do
        install_image_magic
        gem.install 'rmagick'
      end
      
      desc "setup extra paths required for deployment"
      task :setup_paths, :roles => :app do
        # XXX make a function to create a group writable dir
        sudo "test -d #{shared_path}/config || sudo mkdir -p #{shared_path}/config"
        sudo "chgrp -R #{group} #{deploy_to}"
        sudo "chmod -R g+w #{deploy_to}"
      end
      
      desc "create deployment group and add current user to it"
      task :setup_user_perms do
        deprec.groupadd(group)
        deprec.add_user_to_group(user, group)
      end
      
      task :install_rails_stack do
        web_server_type
        app_server_type
        db_server_type
        puts "selected: #{web_server_type} #{app_server_type} #{db_server_type}"
      end
      
      desc "setup and configure servers"
      task :setup_servers do
        setup_web
        setup_paths
        setup_app
        setup_symlinks
        setup_db # XXX fails is database already exists
      end

      task :after_symlink, :roles => :app do
        set_perms_for_mongrel_dirs
      end
      
      desc "Setup web server."
      task :setup_web, :roles => :web  do
        set :apache_server_name, domain unless apache_server_name
        setup_apache
        configure_apache
      end
      
      desc "Setup public symlink directories"
      task :setup_symlinks, :roles => [:app, :web] do
        if app_symlinks
          app_symlinks.each { |link| run "mkdir -p #{shared_path}/public/#{link}" }
        end
      end
      
      desc "Setup public symlink directories"
      task :setup_symlinks, :roles => [:app, :web] do
       if app_symlinks
         app_symlinks.each { |link| run "mkdir -p #{shared_path}/public/#{link}" }
       end
      end

      desc "Link up any public directories."
      task :symlink_public, :roles => [:app, :web] do
       if app_symlinks
         app_symlinks.each { |link| run "ln -nfs #{shared_path}/public/#{link} #{current_path}/public/#{link}" }
       end
      end
    

      
      desc <<-DESC
      install_rails_stack takes a stock standard ubuntu 'dapper' 6.06.1 server
      and installs everything needed to be a rails machine
      DESC
      task :install_rails_stack do
        setup_user_perms
        enable_universe # we'll need some packages from the 'universe' repository
        disable_cdrom_install # we don't want to have to insert cdrom
        install_packages_for_rails # install packages that come with distribution
        install_rubygems
        install_gems 
        apache_install
      end
      
      desc <<-DESC
      deprecated: this function has been replaced by :before_setup and :after_setup
      DESC
      task :deprec_setup, :except => { :no_release => true } do
        setup
      end

      desc "creates paths required by Capistrano's :setup task"
      task :before_setup, :except => { :no_release => true } do
        setup_paths
      end

      desc "sets up and configures servers "
      task :after_setup, :except => { :no_release => true } do
        setup_servers
      end

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
  end
end