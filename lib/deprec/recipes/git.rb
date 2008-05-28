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
    apt.install( {:base => %w(git)}, :stable)
  end
 
  desc "grant a user access to git repos"
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

  desc "Import project into git repository."
  task :push, :roles => :scm do 
    add_ignores
    puts "Importing application."
    system "git push #{repository} master"
    puts "Your repository is: #{repository}" 
  end
  
  desc "ignore log files, tmp"
  task :add_ignores, :roles => :scm  do
    ignore = <<-FILE
      .DS_Store
      log/*.log
      tmp/**/*
      db/*.sqlite3
    FILE
    ["log", "tmp/cache", "tmp/pids", "tmp/sessions", "tmp/sockets"].each do |dir|
      system("touch #{dir}/.gitignore")
    end
    File.open(".gitignore", "w") { |f| f.write(ignore.strip.gsub(/^#{ignore[/\A\s*/]}/, "")) }
    system "find . -type d -empty | xargs -I {} touch {}/.gitignore"
    system "git add ."
    system "git commit -a -m 'Touched .gitignore to emtpy folders, ignored log files, tmp, sqlite3 db'"
  end
  
  end end
end
