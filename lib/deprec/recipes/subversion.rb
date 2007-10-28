require 'fileutils'
require 'uri'

Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do namespace :svn do
  
  set :scm_group, 'scm'
  
  # Extract svn attributes from :repository URL
  # 
  # Two examples of :repository entries are:
  #
  #   set :repository, 'svn+ssh://scm.deprecated.org/var/svn/deprec/trunk'
  #   set :repository, 'file:///tmp/svn/deprec/trunk'
  #
  # This has only been tested with svn+ssh but file: should work.
  #
  set (:svn_scheme) { URI.parse(repository).scheme }  
  set (:svn_host)   { URI.parse(repository).host }
  set (:repos_path) { URI.parse(repository).path }
  set (:repos_root) { 
    URI.parse(repository).path.sub(/\/(trunk|tags|branches)$/, '') 
  }
  
  # account name to perform actions on (such as granting access to an account)
  # this is a hack to allow us to optionally pass a variable to tasks 
  set (:svn_account) do
    Capistrano::CLI.ui.ask 'account name'
  end
  
  set(:svn_backup_dir) { File.join(backup_dir, 'svn') }
  
  # XXX requires apache to have already been installed...
  desc "install Subversion version control system"
  task :install, :roles => :scm do
    # svn 1.4 server improves on 1.3 and is backwards compatible with 1.3 clients
    # http://subversion.tigris.org/svn_1.4_releasenotes.html
    #
    # We're using FSFS instead of BerkeleyDB. Read why below:
    # http://svnbook.red-bean.com/nightly/en/svn-book.html#svn.reposadmin.basics.backends
    #
    # NOTE: we're bulding the python bindings for trac
    # ./subversion/bindings/swig/INSTALL
    #
    version = 'subversion-1.4.5'
    set :src_package, {
      :file => version + '.tar.gz',   
      :md5sum => '3caf1d93e13ed09d76c42eff0f52dfaf  subversion-1.4.5.tar.gz', 
      :dir => version,  
      :url => "http://subversion.tigris.org/downloads/#{version}.tar.gz",
      :unpack => "tar zxf #{version}.tar.gz;",
      :configure => %w(
        ./configure 
        --prefix=/usr/local
        --with-apxs=/usr/local/apache2/bin/apxs
        --with-apr=/usr/local/apache2 
        --with-apr-util=/usr/local/apache2
        PYTHON=/usr/bin/python
        ;
        ).reject{|arg| arg.match '#'}.join(' ') , # DRY this up
      :make => 'make;',
      :install => 'make install;',
      :post_install => '
        make swig-py; 
        make install-swig-py;
        echo /usr/local/lib/svn-python > /usr/lib/python2.4/site-packages/subversion.pth;
        '
    }
    enable_universe
    # XXX should really check if apache has already been installed
    # XXX can do that when we move to rake
    deprec2.download_src(src_package, src_dir)
    deprec2.install_from_src(src_package, src_dir)
  end
  
  desc "install dependencies for apache"
  task :install_deps do
    puts "This function should be overridden by your OS plugin!"
    apt.install( {:base => %w(build-essential wget libneon25 libneon25-dev swig python-dev)}, :stable )
  end
  
  desc "grant a user access to svn repos"
  task :svn_grant_user_access, :roles => :scm do
    deprec.useradd(svn_account)
    deprec.groupadd(scm_group) 
    deprec.add_user_to_group(svn_account, scm_group)
  end
  
  desc "Create subversion repository and import project into it"
  task :svn_setup, :roles => :scm do 
    svn_create_repos
    svn_import
  end
  
  task :scm_setup, :roles => :scm do # deprecated
    svn_setup
  end
  
  task :svn_import_project, :roles => :scm do # deprecated
    svn_setup
  end
  
  desc "Create a subversion repository"
  task :svn_create_repos, :roles => :scm do
    set :svn_account, user
    svn_grant_user_access
    deprec.mkdir(repos_root, :mode => '2775', :group => scm_group)
    sudo "svnadmin verify #{repos_root} > /dev/null 2>&1 || sudo svnadmin create #{repos_root}"
    sudo "chmod -R g+w #{repos_root}"
  end
  
  # Adapted from code in Bradley Taylors RailsMachine gem
  desc "Import project into subversion repository."
  task :svn_import, :roles => :scm do 
    new_path = "../#{application}"
    tags = repository.sub("trunk", "tags")
    branches = repository.sub("trunk", "branches")
    puts "Adding branches and tags"
    system "svn mkdir -m 'Adding tags and branches directories' #{tags} #{branches}"
    puts "Importing application."
    system "svn import #{repository} -m 'Import'"
    cwd = Dir.getwd
    puts "Moving application to new directory"
    Dir.chdir '../'
    system "mv #{cwd} #{cwd}.imported"
    puts "Checking out application."
    system "svn co #{repository} #{application}"
    Dir.chdir application
    svn_remove_log_and_tmp
    puts "Your repository is: #{repository}" 
  end
  
  # Lifted from Bradley Taylors RailsMachine gem
  desc "remove and ignore log files and tmp from subversion"
  task :svn_remove_log_and_tmp, :roles => :scm  do
    puts "removing log directory contents from svn"
    system "svn remove log/*"
    puts "ignoring log directory"
    system "svn propset svn:ignore '*.log' log/"
    system "svn update log/"
    puts "removing contents of tmp sub-directorys from svn"
    system "svn remove tmp/cache/*"
    system "svn remove tmp/pids/*"
    system "svn remove tmp/sessions/*"
    system "svn remove tmp/sockets/*"
    puts "ignoring tmp directory"
    system "svn propset svn:ignore '*' tmp/cache"
    system "svn propset svn:ignore '*' tmp/pids"
    system "svn propset svn:ignore '*' tmp/sessions"
    system "svn propset svn:ignore '*' tmp/sockets"
    system "svn update tmp/"
    puts "committing changes"
    system "svn commit -m 'Removed and ignored log files and tmp'"
  end
  
  # desc "Cache svn name and password on the server. Useful for http-based repositories."
  task :svn_cache_credentials do
    run_with_input "svn list #{repository}"
  end
  
  desc "create backup of trac repository"
  task :backup, :roles => :scm do
    # http://svnbook.red-bean.com/nightly/en/svn.reposadmin.maint.html#svn.reposadmin.maint.backup
    # XXX do we need this? insane!
    # echo "REPOS_BASE=/var/svn" > ~/.svntoolsrc
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    dest_dir = File.join(svn_backup_dir, "svn_#{application}_#{timestamp}")
    run "svn-dump #{application} #{dest_dir}"
  end

  task :restore, :roles => :scm do
    # prompt user to select from list of locally stored backups
    # tracd_stop
    # copy out backup
  end
  
  
  # XXX TODO
  # desc "backup repository" 
  # task :svn_backup_respository, :roles => :scm do
  #   puts "read http://svnbook.red-bean.com/nightly/en/svn-book.html#svn.reposadmin.maint.backup"
  # end

  end end
end
