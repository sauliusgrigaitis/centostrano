require 'deprec/recipes/ssh'
require 'deprec/recipes/svn'
require 'deprec/recipes/trac'
require 'deprec/recipes/rails'
require 'deprec/recipes/ubuntu'
require 'deprec/recipes/apache'
require 'deprec/recipes/memcache'
require 'deprec/third_party/mongrel_cluster/recipes'
require 'deprec/third_party/vmbuilder/plugins'
require 'deprec/third_party/railsmachine/recipes/apache'
require 'deprec/third_party/railsmachine/recipes/mysql'
require 'deprec/capistrano_extensions/cli_extensions.rb'
require 'deprec/capistrano_extensions/deprec_extensions.rb'
require 'deprec/capistrano_extensions/actor_extensions.rb'

Capistrano.configuration(:must_exist).load do
  set :application, lambda { Capistrano::CLI.prompt "Enter application name" }
  set :user, (defined?(user) ? user : ENV['USER']) # user who is deploying
  set :group, 'deploy'           # deployment group
  set :src_dir, (defined?(src_dir) ? src_dir : '/usr/local/src') # 3rd party src on servers 
  set :app_symlinks, nil
  set :mongrel_user_prefix,  'mongrel_'
  set :mongrel_user, lambda {mongrel_user_prefix + application}
  set :mongrel_group_prefix,  'app_'
  set :mongrel_group, lambda {mongrel_group_prefix + application}
    
  desc <<-DESC
  setup_rails_host takes a stock standard ubuntu 'dapper' 6.06.1 server
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
  
  desc "Setup web server."
  task :setup_web, :roles => :web  do
    set :apache_server_name, domain unless apache_server_name
    setup_apache
    configure_apache
  end
  
  desc "create user and group for mongel to run as"
  task :create_mongrel_user_and_group do
    set :mongrel_user, 'mongrel_' + application if mongrel_user.nil?
    set :mongrel_group, 'app_' + application if mongrel_group.nil?
    deprec.groupadd(mongrel_group) 
    deprec.useradd(mongrel_user, :group => mongrel_group, :homedir => false)
    sudo "usermod --gid #{mongrel_group} #{mongrel_user}"
  end
  
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
  
  desc "Restart application server."
  task :restart_app, :roles => :app  do
    restart_mongrel_cluster
  end
  
  desc "Start application server."
  task :start_app, :roles => :app  do
    start_mongrel_cluster
  end

  desc "Start the processes on the application server by calling start_app."
  task :spinner, :roles => :app do
    start_app
  end
  
  desc "Setup public symlink directories"
  task :setup_symlinks, :roles => [:app, :web] do
    if app_symlinks
      app_symlinks.each { |link| run "mkdir -p #{shared_path}/public/#{link}" }
    end
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
  
  desc "setup extra paths required for deployment"
  task :setup_paths, :roles => :app do
    # XXX make a function to create a group writable dir
    sudo "test -d #{shared_path}/config || sudo mkdir -p #{shared_path}/config"
    sudo "chgrp -R #{group} #{deploy_to}"
    sudo "chmod -R g+w #{deploy_to}"
  end
  
  task :install_gems do
    gem.install 'rails'                 # gem lib makes installing gems fun
    gem.select 'mongrel'                # mongrel requires we select a version
    gem.install 'mongrel_cluster'
    gem.install 'builder'
  end
  
  desc "create deployment group and add current user to it"
  task :setup_user_perms do
    deprec.groupadd(group)
    deprec.add_user_to_group(user, group)
  end
  
  task :install_rubygems do
    # XXX should check for presence of ruby first!
    version = 'rubygems-0.9.2'
    set :src_package, {
      :file => version + '.tgz',
      :md5sum => 'cc525053dd465ab6e33af382166fa808  rubygems-0.9.2.tgz',
      :dir => version,
      :url => "http://rubyforge.org/frs/download.php/17190/#{version}.tgz",
      :unpack => "tar zxf #{version}.tgz;",
      :install => '/usr/bin/ruby1.8 setup.rb;'
    }
    deprec.download_src(src_package, src_dir)
    deprec.install_from_src(src_package, src_dir)
    gem.upgrade
    gem.update_system
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
  
  desc "install the rmagic gem, and dependent image-magick library"
  task :install_rmagick, :roles => [:app, :web] do
    install_image_magic
    gem.install 'rmagick'
  end
  
  # Craig: I've kept this generic rather than calling the task setup postfix. 
  # if people want other smtp servers, it could be configurable
  desc "install and configure postfix"
  task :setup_smtp_server do
    install_postfix
    set :postfix_destination_domains, [domain] + apache_server_aliases
    deprec.render_template_to_file('postfix_main', '/etc/postfix/main.cf')
  end
     
  task :setup_admin_account do
    user = Capistrano::CLI.prompt "Enter userid for new user" 
    deprec.useradd(user, :shell => '/bin/bash')
    puts "Setting pasword for new account"
    sudo_with_input("passwd #{user}", /UNIX password/) # ??? how many  versions of the prompt are there?
    deprec.groupadd('admin')
    deprec.add_user_to_group(user, 'admin')
    deprec.append_to_file_if_missing('/etc/sudoers', '%admin ALL=(ALL) ALL')
  end
  
  task :setup_admin_account_as_root do
    as_root { setup_admin_account }
  end 
  
  desc "Change password for the root account"
  task :change_root_password do
    sudo_with_input("passwd root", /UNIX password/) # ??? how many  versions of the prompt are there?
  end

  task :change_root_password_as_root do
    as_root { change_root_password }
  end

  
end
