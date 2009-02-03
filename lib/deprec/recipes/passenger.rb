# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :centos do 
    namespace :passenger do
      
      set :passenger_use_ree, true
      
      set(:passenger_install_dir) { 
        if passenger_use_ree
          "#{ree_install_dir}/lib/ruby/gems/1.8/gems/passenger-2.0.6"
        else
          '/opt/passenger'
        end
      }
      

      set(:passenger_document_root) { "#{current_path}/public" }
      set :passenger_rails_allow_mod_rewrite, 'off'
      set :passenger_vhost_dir, '/usr/local/apache2/conf/apps'
      # Default settings for Passenger config files
      set :passenger_log_level, 0
      set :passenger_user_switching, 'on'
      set :passenger_default_user, 'nobody'
      set :passenger_max_pool_size, 6
      set :passenger_max_instances_per_app, 0
      set :passenger_pool_idle_time, 300
      set :passenger_rails_autodetect, 'on'
      set :passenger_rails_spawn_method, 'smart' # smart | conservative

      SRC_PACKAGES[:passenger] = {
        :url => "git://github.com/FooBarWidget/passenger.git",
        :download_method => :git,
        :version => 'release-2.0.6', # Specify a tagged release to deploy
        :configure => '',
        :make => '',
        :install => ' ./bin/passenger-install-apache2-module'
      }
      
      SYSTEM_CONFIG_FILES[:passenger] = [
      # Hmm...we need to place those non-app config files somewhere else - Saulius
        {:template => 'passenger.load.erb',
          :path => '/usr/local/apache2/conf/apps/passenger.load',
          :mode => 0755,
          :owner => 'root:root'},

        {:template => 'passenger.conf.erb',
          :path => '/usr/local/apache2/conf/apps/passenger.conf',
          :mode => 0755,
          :owner => 'root:root'}


      ]

      PROJECT_CONFIG_FILES[:passenger] = [

        { :template => 'apache_vhost.erb',
          :path => 'apache_vhost',
          :mode => 0755,
          :owner => 'root:root'}

      ]

      desc "Install passenger"
      task :install, :roles => :passenger do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:passenger], src_dir)

        if passenger_use_ree
          # needs porting to CentOS - Saulius
          # Install the Passenger that came with Ruby Enterprise Edition
          run "yes | #{sudo} env PATH=#{ree_install_dir}/bin:$PATH #{ree_install_dir}/bin/passenger-install-apache2-module"
        else
          package_dir = File.join(src_dir, 'passenger.git')
          dest_dir = passenger_install_dir + '-' + (SRC_PACKAGES[:passenger][:version] || 'trunk')
          run "#{sudo} rsync -avz #{package_dir}/ #{dest_dir}"
          sudo "su -c 'export PATH=/usr/local/apache2/bin:$PATH && export APXS2=/usr/local/apache2/bin/apxs && export APR_CONFIG=/usr/local/apache2/bin/apr-1-config && cd #{dest_dir} && yes '' | ./bin/passenger-install-apache2-module'"
          #run "cd #{dest_dir} && #{sudo} ./bin/passenger-install-apache2-module"
          run "#{sudo} unlink #{passenger_install_dir} 2>/dev/null; #{sudo} ln -sf #{dest_dir} #{passenger_install_dir}"
        end
          
        initial_config_push
      end

      task :initial_config_push, :roles => :web do
        # XXX Non-standard!
        # We need to push out the .load and .conf files for Passenger
        SYSTEM_CONFIG_FILES[:passenger].each do |file|
          deprec2.render_template(:passenger, file.merge(:remote => true))
        end
      end

      # install dependencies for nginx
      task :install_deps, :roles => :passenger do
        apt.install( {:base => %w(rsync apr-devel)}, :stable )
        gem2.install 'fastthread'
        gem2.install 'rack'
        gem2.install 'rake'
        top.centos.apache.install
      end
       
      desc "Generate Passenger apache configs (system & project level)."
      task :config_gen do
        config_gen_system 
        config_gen_project
      end

      desc "Generate Passenger apache configs (system level) from template."
      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:passenger].each do |file|
          deprec2.render_template(:passenger, file)
        end
      end

      desc "Generate Passenger apache configs (project level) from template."
      task :config_gen_project do
        PROJECT_CONFIG_FILES[:passenger].each do |file|
          deprec2.render_template(:passenger, file)
        end
      end

      desc "Push Passenger config files (system & project level) to server"
      task :config, :roles => :app do
        config_system
        config_project  
      end

      desc "Push Passenger configs (system level) to server"
      task :config_system, :roles => :app do
        deprec2.push_configs(:passenger, SYSTEM_CONFIG_FILES[:passenger])
        activate_system
      end

      desc "Push Passenger configs (project level) to server"
      task :config_project, :roles => :app do
        deprec2.push_configs(:passenger, PROJECT_CONFIG_FILES[:passenger])
        symlink_passenger_vhost
        activate_project
      end

      task :symlink_passenger_vhost, :roles => :app do
        sudo "ln -sf #{deploy_to}/passenger/apache_vhost #{passenger_vhost_dir}/#{application}.conf"
      end
      
      task :activate do
        activate_system
        activate_project
      end
      
      task :activate_system do
        #sudo "a2enmod passenger"
        top.centos.web.reload
      end
      
      task :activate_project do
        #sudo "a2ensite #{application}"
        top.centos.web.reload
      end
      
      task :deactivate do
        puts
        puts "******************************************************************"
        puts
        puts "Danger!"
        puts
        puts
        puts "Do you want to deactivate just this project or all Passenger"
        puts "projects on this server? Try a more granular command:"
        puts
        puts "cap centos:passenger:deactivate_system  # disable Passenger"
        puts "cap centos:passenger:deactivate_project # disable only this project"
        puts
        puts "******************************************************************"
        puts
      end
      
      task :deactivate_system do
        #sudo "a2dismod passenger"
        top.centos.web.reload
      end
      
      task :deactivate_project do
        #sudo "a2dissite #{application}"
        top.centos.web.reload
      end
      
      desc "Restart Application"
      task :restart, :roles => :app do
        run "touch #{current_path}/tmp/restart.txt"
      end
      
      desc "Restart Apache"
      task :restart_apache, :roles => :passenger do
        run "#{sudo} /etc/init.d/httpd restart"
      end
      
      namespace :ree do
      # need to port to CentOS all that REE thing - Saulius
        set :ree_version, 'ruby-enterprise-1.8.6-20090113'
        set :ree_install_dir, "/opt/#{ree_version}"
        set :ree_short_path, '/opt/ruby-enterprise'
        
        SRC_PACKAGES[:ree] = {
          :md5sum => "e8d796a5bae0ec1029a88ba95c5d901d #{ree_version}.tar.gz",
          :url => "http://rubyforge.org/frs/download.php/50087/#{ree_version}.tar.gz",
          :configure => '',
          :make => '',
          :install => "./installer --auto /opt/#{ree_version}"
        }
   
        task :install do
          install_deps
          deprec2.download_src(SRC_PACKAGES[:ree], src_dir)
          deprec2.install_from_src(SRC_PACKAGES[:ree], src_dir)
          symlink_ree
        end
        
        task :install_deps do
          apt.install({:base => %w(libssl-dev libmysqlclient15-dev libreadline5-dev)}, :stable)
        end
        
        task :symlink_ree do
          sudo "ln -sf /opt/#{ree_version} #{ree_short_path}"
          sudo "ln -fs #{ree_short_path}/bin/gem /usr/local/bin/gem"
          sudo "ln -fs #{ree_short_path}/bin/irb /usr/local/bin/irb"
          sudo "ln -fs #{ree_short_path}/bin/rake /usr/local/bin/rake"
          sudo "ln -fs #{ree_short_path}/bin/rails /usr/local/bin/rails"
          sudo "ln -fs #{ree_short_path}/bin/ruby /usr/local/bin/ruby"
        end
        
      end
    

    end
  end
end
