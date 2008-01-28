Capistrano::Configuration.instance(:must_exist).load do 

  set :database_yml_in_scm, false
  set :app_symlinks, nil
  set :rails_env, 'production'

  # Hook into the default capistrano deploy tasks
  before 'deploy:setup', :except => { :no_release => true } do
    top.deprec.rails.setup_user_perms
    top.deprec.rails.setup_paths
    top.deprec.rails.setup_shared_dirs
  end
  
  # Override default cap task using sudo to create dir
  namespace :deploy do
    task :setup, :except => { :no_release => true } do
      dirs = [deploy_to, releases_path, shared_path]
      dirs += %w(system log pids).map { |d| File.join(shared_path, d) }
      sudo "sh -c 'umask 02 && mkdir -p #{dirs.join(' ')}'"
    end
  end

  after 'deploy:setup', :except => { :no_release => true } do
    top.deprec.rails.setup_servers
  end

  after 'deploy:symlink', :roles => :app do
    top.deprec.rails.symlink_shared_dirs
    top.deprec.rails.symlink_database_yml unless database_yml_in_scm
    top.deprec.mongrel.set_perms_for_mongrel_dirs
  end

  after :deploy, :roles => :app do
    deploy.cleanup
  end

  # redefine the reaper
  namespace :deploy do
    task :restart do
      top.deprec.mongrel.restart
      top.deprec.nginx.restart
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

      task :install, :roles => :app do
        install_deps
        install_gems
      end

      task :install_deps do
        apt.install( {:base => %w(libmysqlclient15-dev sqlite3 libsqlite3-ruby libsqlite3-dev)}, :stable )
      end

      # install some required ruby gems
      task :install_gems do
        gem2.install 'sqlite3-ruby'
        gem2.install 'mysql'
        gem2.install 'rails'
        gem2.install 'rspec' # seems to be required to run rake db:migrate (???)
        # gem2.install 'builder' # XXX ? needed ?
        install_gems_for_project
      end
      
      # task :install_gems_for_project do
      #     if gems_for_project
      #       gems_for_project.each { |gem| gem2.install(gem) }
      #     end
      # end

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

      # create deployment group and add current user to it
      task :setup_user_perms do
        deprec2.groupadd(group)
        deprec2.add_user_to_group(user, group)
      end

      # Setup database server.
      task :setup_db, :roles => :db, :only => { :primary => true } do
        top.deprec.mysql.setup
      end

      # setup extra paths required for deployment
      task :setup_paths, :roles => :app do
        deprec2.mkdir(deploy_to, :mode => '0775', :group => group, :via => :sudo)
        deprec2.mkdir(shared_path, :mode => '0775', :group => group, :via => :sudo)
      end
      
      # Symlink list of files and dirs from shared to current
      #
      # XXX write up explanation
      #
      desc "Setup shared dirs"
      task :setup_shared_dirs, :roles => [:app, :web] do
        if shared_dirs
          shared_dirs.each { |dir| deprec2.mkdir( "#{shared_path}/#{dir}", :via => :sudo ) }
        end
      end
      #
      desc "Symlink shared dirs."
      task :symlink_shared_dirs, :roles => [:app, :web] do
        if shared_dirs
          shared_dirs.each { |dir| run "ln -nfs #{shared_path}/#{dir} #{current_path}/#{dir}" }
        end
      end
      
      # desc "Symlink shared files."
      # task :symlink_shared_files, :roles => [:app, :web] do
      #   if shared_files
      #     shared_files.each { |file| run "ln -nfs #{shared_path}/#{file} #{current_path}/#{file}" }
      #   end
      # end

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
        run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml" 
      end

      desc <<-DESC
      install_rails_stack takes a stock standard ubuntu 'gutsy' 7.10 server
      and installs everything needed to be a Rails machine
      DESC
      task :install_rails_stack do

        # Nginx as our web frontend
        top.deprec.nginx.install
        top.deprec.nginx.config_gen
        top.deprec.nginx.config
        
        # Subversion
        top.deprec.svn.install

        # Ruby
        top.deprec.ruby.install      
        top.deprec.rubygems.install      
        
        # Mongrel as our app server
        top.deprec.mongrel.install
        top.deprec.mongrel.config_gen_system
        top.deprec.mongrel.config_system

        # Install mysql
        # top.deprec.mysql.install
        # top.deprec.mysql.start
        
        # Install rails
        top.deprec.rails.install
      end
      
      desc "setup and configure servers"
      task :setup_servers do

        top.deprec.nginx.activate        
        top.deprec.mongrel.config_gen
        top.deprec.mongrel.config
        top.deprec.mongrel.create_mongrel_user_and_group
        top.deprec.mongrel.activate
        top.deprec.rails.config_gen
        top.deprec.rails.config
      end
    end

    namespace :db do
      
      desc "Create database"
      task :create, :roles => :db do
        run "cd #{deploy_to}/current && rake db:create RAILS_ENV=#{rails_env}"
      end

      desc "Run database migrations"
      task :migrate, :roles => :db do
        run "cd #{deploy_to}/current && rake db:migrate RAILS_ENV=#{rails_env}"
      end

      desc "Roll database back to previous migration"
      task :rollback, :roles => :db do
        run "cd #{deploy_to}/current && rake db:rollback RAILS_ENV=#{rails_env}"
      end

    end


    namespace :deploy do
      task :restart, :roles => :app, :except => { :no_release => true } do
        top.deprec.mongrel.restart
      end
    end
  end
end