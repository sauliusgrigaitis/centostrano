# Copyright 2006-2008 by Saulius Grigaitis. All rights reserved.
require 'fileutils'
require 'uri'
require 'optparse'


Capistrano::Configuration.instance(:must_exist).load do 
  namespace :centos do namespace :git do
  
  set :scm_group, 'scm'
  # Extract git attributes from :repository URL
  # 
  # Two examples of :repository entries are:
  #
  #   set :repository, 'ssh://www.rubyonrails.lt/var/git/centostrano.git'
  #
  # This has only been tested with ssh (haven't tested with git or http)
  #
  set (:git_scheme) { URI.parse(repository).scheme }  
  set (:git_host)   { URI.parse(repository).host }
  set (:git_path) { URI.parse(repository).path }
  
  # account name to perform actions on (such as granting access to an account)
  # this is a hack to allow us to optionally pass a variable to tasks 
  set (:git_account) do
    Capistrano::CLI.ui.ask 'account name'
  end
  
  set(:git_backup_dir) { File.join(backup_dir, 'git') }
  

  desc "Install Git"
  task :install, :roles => :scm do
    install_deps
  end
  
  desc "install dependencies for Subversion"
  task :install_deps do
    enable_atrpms_dag_repositories
    apt.install( {:base => %w(git)}, :stable , {:repositories => [:atrpms, :dag]})
  end
 
  desc "enable atrmps and dag repositories"
  task :enable_atrpms_dag_repositories do
    repository_configs = [
      {
        :template => 'repository.erb',
        :path => '/etc/yum.repos.d/atrpms.repo',
        :mode => 0644,
        :owner => 'root:root',
        :remote => true,
        :repository => { 
          :code => "atrpms",
          :name => "ATrpms for Enterprise Linux $releasever - $basearch",
          :baseurl => "http://dl.atrpms.net/el$releasever-$basearch/atrpms/stable",
          :enabled => "0",
          :gpgcheck => "1",
          :gpgkey => "http://ATrpms.net/RPM-GPG-KEY.atrpms"
        }
      },
      {
        :template => 'repository.erb',
        :path => '/etc/yum.repos.d/dag.repo',
        :mode => 0644,
        :owner => 'root:root',
        :remote => true,
        :repository => { 
          :code => "dag",
          :name => "Dag",
          :baseurl => "http://dag.freshrpms.net/redhat/el4/en/$basearch/dag\nhttp://ftp.heanet.ie/pub/freshrpms/pub/dag/redhat/el4/en/i386/dag/",
          :enabled => "0",
          :gpgcheck => "1",
          :gpgkey => "http://dag.wieers.com/packages/RPM-GPG-KEY.dag.txt"
        }
      } 
    ]
    repository_configs.each { |rc| deprec2.render_template(:centos, rc) }
  end

  desc "grant a user access to svn repos"
  task :grant_user_access, :roles => :scm do
    # creates account, scm_group and adds account to group
    deprec2.useradd(git_account)
    deprec2.groupadd(scm_group) 
    deprec2.add_user_to_group(git_account, scm_group)
  end
  
  desc "Create git repository and import project into it"
  task :setup, :roles => :scm do 
    create_repos
    create_local_repos
    push 
  end
 
  desc "Create a git repository"
  task :create_repos, :roles => :scm do
    set :git_account, top.user
    grant_user_access
    deprec2.mkdir(repos_path, :mode => 02775, :group => scm_group, :via => :sudo)
    sudo "sh -c 'cd #{repos_path} && git --bare init'"
    sudo "chmod -R g+w #{repos_path}"
  end
 
  desc "Create git repository in local project"
  task :create_local_repos do
    unless File.exists?(".git")
      system("git init")
      system("git add .")
      system("git commit -a -m 'Initial import'")
    end
  end

  # Adapted from code in Bradley Taylors RailsMachine gem
  desc "Import project into git repository."
  task :push, :roles => :scm do 
    ignore_log_and_tmp
    new_path = "../#{application}"
    puts "Importing application."
    system "git push #{repository} master"
    puts "Your repository is: #{repository}" 
  end
  
  # Lifted from Bradley Taylors RailsMachine gem
  desc "ignore log files and tmp"
  task :ignore_log_and_tmp, :roles => :scm  do
    puts "removing log directory contents from git"
    system "rm log/*"
    puts "removing contents of tmp sub-directorys from git"
    system "rm tmp/cache/*"
    system "rm tmp/pids/*"
    system "rm tmp/sessions/*"
    system "rm tmp/sockets/*"

    ignore = <<-FILE
      .DS_Store
      log/*.log
      tmp/**/*
      db/*.sqlite3
      coverage
      doc/app/*
      doc/api/*
    FILE
      
    File.open(".gitignore", "w") { |f| f.write(ignore.strip.gsub(/^#{ignore[/\A\s*/]}/, "")) }
    system "find . -type d -empty | xargs -I {} touch {}/.gitignore"
    system "git add ."
    system "git commit -a -m 'Touched .gitignore to emtpy folders and  ignored log files and tmp'"
  end
  
  end end
end
