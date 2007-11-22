Capistrano::Configuration.instance(:must_exist).load do 
  
  namespace :deprec do
    namespace :mongrel do
      
      set :mongrel_servers, 2
      set :mongrel_port, 8000
      set :mongrel_address, "127.0.0.1"
      set :mongrel_environment, "production"
      set :mongrel_conf, nil
      set :mongrel_user, nil
      set :mongrel_group, nil
      set :mongrel_prefix, nil
  
      set :mongrel_user_prefix,  'mongrel_'
      set :mongrel_user, lambda {mongrel_user_prefix + application}
      set :mongrel_group_prefix,  'app_'
      set :mongrel_group, lambda {mongrel_group_prefix + application}
      
      desc "Install example"
      task :install, :roles => :app do
        gem2.select 'mongrel'                # mongrel requires we select a version
        gem2.install 'mongrel_cluster'
      end
      
      desc "Generate configuration file(s) for XXX from template(s)"
      task :config_gen, :roles => :app do
      end
      
      desc 'Deploy configuration files(s) for XXX' 
      task :config, :roles => :app do
      end
      
      desc "Start application server."
      task :start, :roles => :app do
        # start_mongrel_cluster
      end
      
      task :stop, :roles => :app do
      end
      
      desc "Restart application server."
      task :restart, :roles => :app do
        sudo "/etc/init.d/mongrel_cluster restart"
      end
      
      task :activate, :roles => :app do
      end  
      
      task :deactivate, :roles => :app do
      end
      
      task :backup, :roles => :app do
      end
      
      task :restore, :roles => :app do
      end
      
      desc "Setup application server."
      task :setup, :roles => :app  do
        set :mongrel_environment, rails_env
        set :mongrel_port, apache_proxy_port
        set :mongrel_servers, apache_proxy_servers
        create_mongrel_user_and_group
        install_mongrel_start_script
        setup_mongrel_cluster_path
        configure_mongrel_cluster
      end
      
      desc "create user and group for mongel to run as"
      task :create_mongrel_user_and_group, :roles => :app do
        set :mongrel_user, 'mongrel_' + application if mongrel_user.nil?
        set :mongrel_group, 'app_' + application if mongrel_group.nil?
        deprec.groupadd(mongrel_group) 
        deprec.useradd(mongrel_user, :group => mongrel_group, :homedir => false)
        sudo "usermod --gid #{mongrel_group} #{mongrel_user}"
      end
      
      desc "set group ownership and permissions on dirs mongrel needs to write to"
      task :set_perms_for_mongrel_dirs, :roles => :app do
        tmp_dir = "#{deploy_to}/current/tmp"
        shared_dir = "#{deploy_to}/shared"
        files = ["#{deploy_to}/shared/log/mongrel.log", "#{deploy_to}/shared/log/#{rails_env}.log"]

        sudo "chgrp -R #{mongrel_group} #{tmp_dir} #{shared_dir}"
        sudo "chmod -R g+w #{tmp_dir} #{shared_dir}" 
        # set owner and group of mongrels file (if they exist)
        files.each { |file|
          sudo "chown #{mongrel_user} #{file} || exit 0"   
          sudo "chgrp #{mongrel_group} #{file} || exit 0"  
        } 
      end
      
    end
  end
end