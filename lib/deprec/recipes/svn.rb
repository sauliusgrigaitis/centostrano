require 'fileutils'

Capistrano.configuration(:must_exist).load do
  
  # By default, all repositories are group writable by the group 'scm'
  # Originally I have envisaged this value being initialized here as:
  #
  #   set :scm_group, lambda {'scm_' + application} 
  #
  # however the SVN docs convinced me it's probably overkill.
  # http://svnbook.red-bean.com/nightly/en/svn-book.html#svn.serverconfig.pathbasedauthz
  set :scm_group, 'scm'
  
  set :svn_root, '/usr/local/svn'
  
  
  desc "install Subversion version control system"
  task :install_svn do
    # svn 1.4 server improves on 1.3 and is backwards compatible with 1.3 clients
    # http://subversion.tigris.org/svn_1.4_releasenotes.html
    #
    # We're using FSFS instead of BerkeleyDB. Read why below:
    # http://svnbook.red-bean.com/nightly/en/svn-book.html#svn.reposadmin.basics.backends
    #
    version = 'subversion-1.4.3'
    set :src_package, {
      :file => version + '.tar.gz',   
      :md5sum => '6b991b63e3e1f69670c9e15708e40176 subversion-1.4.3.tar.gz', 
      :dir => version,  
      :url => "http://subversion.tigris.org/downloads/#{version}.tar.gz",
      :unpack => "tar zxf #{version}.tar.gz;",
      :configure => %w(
        ./configure 
        --prefix=/usr/local
        --with-apxs=/usr/local/apache2/bin/apxs
        --with-apr=/usr/local/apache2 
        --with-apr-util=/usr/local/apache2
        ;
        ).reject{|arg| arg.match '#'}.join(' ') , # DRY this up
      :make => 'make;',
      :install => 'make install;'
    }
    apt.install( {:base => %w(libneon25 libneon25-dev)}, :stable )
    deprec.download_src(src_package, src_dir)
    deprec.install_from_src(src_package, src_dir)
  end
  
  desc "create a repository and import a project"
  task :svn_create_repos, :roles => :scm do
    svn_repos ||= "#{svn_root}/#{application}"
    deprec.groupadd(scm_group) 
    deprec.add_user_to_group(user, scm_group)
    deprec.mkdir(svn_root, :mode => '0755')
    deprec.mkdir(svn_repos, :mode => '2775', :group => scm_group)
    sudo "svnadmin verify #{svn_repos} > /dev/null 2>&1 || sudo svnadmin create #{svn_repos}"
    sudo "chmod -R g+w #{svn_repos}"
  end

  # XXX check through and test the next two [mike]
  
  # from Bradley Taylors RailsMachine gem
  desc "Import code into svn repository."
  task :svn_import  do
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
    puts "removing log directory contents from svn"
    system "svn remove log/*"
    puts "ignoring log directory"
    system "svn propset svn:ignore '*.log' log/"
    system "svn update log/"
    puts "removing tmp directory from svn"
    system "svn remove tmp/"
    puts "ignoring tmp directory"
    system "svn propset svn:ignore '*' tmp/"
    system "svn update tmp/"
    puts "committing changes"
    system "svn commit -m 'Removed and ignored log files and tmp'"
    puts "Your repository is: #{repository}" 
  end
  
  # from Bradley Taylors RailsMachine gem
  desc "remove and ignore log files and tmp from subversion"
  task :svn_remove_log_and_tmp do
    puts "removing log directory contents from svn"
    system "svn remove log/*"
    puts "ignoring log directory"
    system "svn propset svn:ignore '*.log' log/"
    system "svn update log/"
    puts "removing tmp directory from svn"
    system "svn remove tmp/"
    puts "ignoring tmp directory"
    system "svn propset svn:ignore '*' tmp/"
    system "svn update tmp/"
    puts "committing changes"
    system "svn commit -m 'Removed and ignored log files and tmp'"
  end
  
  desc "Cache svn name and password on the server. Useful for http-based repositories."
  task :svn_cache_credentials do
    run_with_input "svn list #{repository}"
  end
  
  # XXX TODO
  # desc "backup repository" 
  # task :svn_backup_respository, :roles => :scm do
  #   puts "read http://svnbook.red-bean.com/nightly/en/svn-book.html#svn.reposadmin.maint.backup"
  # end

end
