Capistrano::Configuration.instance(:must_exist).load do 
    
  set :database_yml_in_scm, true
  set :app_symlinks, nil
  
  # run "rake db:create" # waiting for Rails2
  
  
  # Hook into the default capistrano deploy tasks
  before 'deploy:setup', :except => { :no_release => true } do
    top.deprec.rails.setup_user_perms
    top.deprec.rails.setup_paths
  end
  
  after 'deploy:setup', :except => { :no_release => true } do
    top.deprec.rails.setup_servers
  end
  
  after 'deploy:update_code', :roles => :app do
    top.deprec.rails.symlink_database_yml unless database_yml_in_scm
  end
  
  after 'deploy:symlink', :roles => :app do
    top.deprec.mongrel.set_perms_for_mongrel_dirs
  end
  
  after :deploy, :roles => :app do
    deploy.cleanup
  end
  
  # redefine the reaper
  namespace :deploy do
    task :restart do
      top.deprec.mongrel.restart
      top.deprec.apache.restart
    end
  end
  
  
  PROJECT_CONFIG_FILES[:nginx] = [
  
    {:template => 'rails_nginx_vhost.conf.erb',
     :path => "rails_nginx_vhost.conf", 
     :mode => '0644',
     :owner => 'root:root'}
  ]
  
  namespace :deprec do
    namespace :rails do
      
      task :config_gen do
        PROJECT_CONFIG_FILES[:nginx].each do |file|
          deprec2.render_template(:nginx, file)
        end
      end
      
      task :config do
        deprec2.push_configs(:nginx, PROJECT_CONFIG_FILES[:nginx])
        symlink_nginx_vhost
      end
      
      task :symlink_nginx_vhost, :roles => :web do
        sudo "ln -sf #{deploy_to}/nginx/rails_nginx_vhost.conf #{nginx_vhost_dir}/#{application}.conf"
      end
      
      desc <<-DESC
      install_rails_stack takes a stock standard ubuntu 'gutsy' 7.10 server
      and installs everything needed to be a Rails machine
      DESC
      task :install_rails_stack do
        
        install_deps
        
        # setup_user_perms
        top.deprec.nginx.install
        top.deprec.nginx.config_gen
        top.deprec.nginx.config
        
        top.deprec.ruby.install      
        top.deprec.rubygems.install      
        install_gems 
        
        top.deprec.mongrel.install
        # top.deprec.mongrel.config_gen
        # top.deprec.mongrel.config
        
        # puts "Installing #{web_server_type}"
        # deprec.web.install
        # puts "Installing #{app_server_type}"
        # deprec.app.install
        # puts "Installing #{db_server_type}"
        # deprec.db.install
      end
      
      task :install_deps do
        apt.install( {:base => %w(libmysqlclient15-dev)}, :stable )
      end
      
      # install some required ruby gems
      task :install_gems do
        gem2.install 'mysql'
        gem2.install 'rails'
        # gem2.install 'builder' # XXX ? needed ?
      end
      
      # create deployment group and add current user to it
      task :setup_user_perms do
        deprec2.groupadd(group)
        deprec2.add_user_to_group(user, group)
      end
      
      # setup extra paths required for deployment
      task :setup_paths, :roles => :app do
        # XXX make a function to create a group writable dir
        sudo "test -d #{shared_path}/config || sudo mkdir -p #{shared_path}/config"
        sudo "chgrp -R #{group} #{deploy_to}"
        sudo "chmod -R g+w #{deploy_to}"
      end
      
      desc "setup and configure servers"
      task :setup_servers do
        setup_web
        setup_paths
        top.deprec.app.setup # currently this will be mongrel
        setup_symlinks
        setup_db
      end
      
      # Setup database server.
      task :setup_db, :roles => :db, :only => { :primary => true } do
        top.deprec.mysql.setup
      end

      desc "Setup web server."
      task :setup_web, :roles => :web  do
        # set :apache_server_name, domain unless apache_server_name
        # setup_apache
        # configure_apache
        top.deprec.nginx.config_gen_project
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
  
      desc "Link in the production database.yml" 
      task :symlink_database_yml, :roles => :app do
        # run "rm -f #{current_path}/config/database.yml"
        run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml" 
      end
      
      desc "install the rmagic gem, and dependent image-magick library"
      task :install_rmagick, :roles => [:app, :web] do
        install_image_magic
        gem.install 'rmagick'
      end
      
      # XXX deprecated?
      # desc "Start the processes on the application server by calling start_app."
      # task :spinner, :roles => :app do
      #   start_app
      # end
  
    end
  end
end