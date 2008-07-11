# Copyright 2008 by Saulius Grigaitis. All rights reserved.
require 'fileutils'
require 'uri'
require 'optparse'

Capistrano::Configuration.instance(:must_exist).load do 
  namespace :centos do namespace :gitosis do
    
  set :scm_group, 'scm'

  set(:git_backup_dir) { File.join(backup_dir, 'git') }

  desc "Install Gitosis"
  task :install, :roles => :scm do
    install_deps
    
    deprec2.groupadd(scm_group)
    deprec2.useradd("git", { :gecos => 'git version control', :shell => '/bin/sh', :group => scm_group, :homedir => "/home/git"})
    # TODO: should git user be locked?
    sudo "/usr/bin/passwd -u -f git" 
    deprec2.add_user_to_group("git", scm_group)
    
    package_dir = File.join(src_dir, 'gitosis')
    sudo <<-SUDO
    sh -c 'cd #{src_dir};
    test -d #{package_dir}.old && rm -fr #{package_dir}.old;
    test -d #{package_dir} && mv #{package_dir} #{package_dir}.old;
    git clone git://eagain.net/gitosis.git #{package_dir};
    chown -R #{user} #{package_dir};  
    chmod -R g+w #{package_dir};
    cd #{package_dir};
    python setup.py install'
    SUDO

            
    unless ssh_options[:keys]  
      puts <<-ERROR

      You need to define the name of your SSH key(s)
     e.g. ssh_options[:keys] = %w(/Users/your_username/.ssh/id_rsa)

      You can put this in your .caprc file in your home directory.

      ERROR
      exit
    end

    put File.read(ssh_options[:keys].first + ".pub"), "/tmp/id_rsa.pub",  :mode => 0600
    sudo "sudo -H -u git gitosis-init < /tmp/id_rsa.pub"
    sudo "sudo rm /tmp/id_rsa.pub"
    sudo "sudo chmod 755 /home/git/repositories/gitosis-admin.git/hooks/post-update"
  end
  
  desc "install dependencies for git"
  task :install_deps do
    yum.enable_repository :epel
    apt.install( {:base => %w(git python-devel python-setuptools)}, :stable)
  end

  desc "Create remote git repository and import project into it"
  task :setup_repo, :roles => :scm do 
     path_dir = "config/gitosis"
    FileUtils.mkdir_p(path_dir) if !File.directory?(path_dir)
    system("git clone git@#{domain}:gitosis-admin.git config/gitosis/gitosis-admin.git") if !File.exists?("#{path_dir}/gitosis-admin.git")

    create_repos
    create_local_repos
    push 
  end
 
  desc "Create a git repository"
  task :create_repos, :roles => :scm do
    gitosis_admin = File.open(ssh_options[:keys].first + ".pub", "r") do |line|
      line.gets.split(" ").last
    end
    # create key pair if it doesn't exist, and fetch public key 
    run "sh -c 'test -f /home/#{user}/.ssh/id_rsa.pub || /usr/bin/ssh-keygen -q -t rsa -N \"\" -f /home/#{user}/.ssh/id_rsa >&/dev/null'"
    #run "chmod 600 /home/#{user}/.ssh/id_rsa && chmod 644 /home/#{user}/.ssh/id_rsa.pub"
    get("/home/#{user}/.ssh/id_rsa.pub", "config/gitosis/gitosis_server.pub")
    gitosis_server = File.open("config/gitosis/gitosis_server.pub", "r") do |line|
      line.gets.split(" ").last
    end
    system("mv config/gitosis/gitosis_server.pub config/gitosis/gitosis-admin.git/keydir/#{gitosis_server}.pub")
    gitosis_conf = <<-GITOSIS

[group #{application}]
writable = #{application}
members = #{gitosis_admin} #{gitosis_server}

    GITOSIS

    File.open("config/gitosis/gitosis-admin.git/gitosis.conf", "a") { |f| f.write(gitosis_conf) }
    system "cd config/gitosis/gitosis-admin.git && git add . && git commit -m \"Added repository #{application} and write permission to user #{gitosis_admin}\" && git push"
  end
 
  desc "Create git repository in local project"
  task :create_local_repos do
    unless File.exists?(".git")
      system("git init")
      system("git remote add origin git@#{domain}:#{application}.git")
      system("git add .")
      system("git commit -a -m 'Initial import'")
    end
  end

  desc "Import project into git repository."
  task :push, :roles => :scm do 
    add_ignores
    puts "Importing application."
    system "git push git@#{domain}:#{application}.git master:refs/heads/master"
    system "git-config --add branch.master.remote origin"
    system "git-config --add branch.master.merge refs/heads/master"
    puts "Your repository is: git@#{domain}:#{application}.git" 
  end
  
  desc "ignore log files, tmp"
  task :add_ignores, :roles => :scm  do
    ignore = <<-FILE
      .DS_Store
      log/*.log
      tmp/**/*
      db/*.sqlite3
      config/gitosis
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
