require 'fileutils'
require 'uri'

Capistrano.configuration(:must_exist).load do
  
  # By default, all repositories are group writable by the group 'scm'
  # Originally I have envisaged this value being initialized here as:
  #
  #   set :scm_group, lambda {'scm_' + application} 
  #
  # however the SVN docs convinced me it's probably overkill.
  # http://svnbook.red-bean.com/nightly/en/svn-book.html#svn.serverconfig.pathbasedauthz
  #
  set :scm_group, 'scm'
  
  # The following values define the svn repository to work with.
  # If any are undefined but :repository is set, we'll extract the 
  # necessary values from it, otherwise we'll prompt the user.
  # 
  # An example of :repository entries are:
  #
  #   set :repository, 'svn+ssh://scm.deprecated.org/var/svn/deprec/trunk'
  #   set :repository, 'file:///tmp/svn/deprec/trunk'
  #
  # I've only used svn+ssh but it shouldn't be hard to get the file scheme working.
  #
  set (:svn_scheme) do
    repository ? URI.parse(repository).scheme : 'svn+ssh'
  end
  
  set (:scm_host) do
    if repository
      URI.parse(repository).host || 'localhost'
    elsif ENV['HOSTS']
      svn_host = ENV['HOSTS']
    else
      Capistrano::CLI.prompt('svn host')
    end
  end

  # This is the actual path in the svn repos where we'll check our project into
  set (:repos_path) do
    repository ? URI.parse(repository).path : Capistrano::CLI.prompt('svn repos path')
  end

  # We'll calculate this based on the repos_path. It's used when initializing the repository
  set (:repos_root) do
    (repository ? URI.parse(repository).path : repos_path).sub(/\/(trunk|tags|branches)$/, '')
  end
  
  # account name to perform actions on
  # this is a hack to allow us to optionally pass a variable to tasks 
  set (:svn_account) do
    Capistrano::CLI.prompt('account name')
  end
  
  # I'd like to be able to construct :repository if it's not explicitly set
  # However we're grabbing values from it in the lines above so it would get a bit recursive
  # set :repository, lambda { "#{svn_scheme}://#{scm_host == 'localhost' ? '/' : user+'@'+scm_host}#{repos_path}" }
  
  # XXX requires apache to have already been installed...
  desc "install Subversion version control system"
  task :svn_install, :roles => :scm do
    # svn 1.4 server improves on 1.3 and is backwards compatible with 1.3 clients
    # http://subversion.tigris.org/svn_1.4_releasenotes.html
    #
    # We're using FSFS instead of BerkeleyDB. Read why below:
    # http://svnbook.red-bean.com/nightly/en/svn-book.html#svn.reposadmin.basics.backends
    #
    # NOTE: we're bulding the python bindings for trac
    # ./subversion/bindings/swig/INSTALL
    #
    version = 'subversion-1.4.4'
    set :src_package, {
      :file => version + '.tar.gz',   
      :md5sum => '702655defa418bab8f683f6268b4fd30  subversion-1.4.4.tar.gz', 
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
    apt.install( {:base => %w(libneon25 libneon25-dev swig python-dev)}, :stable )
    deprec.download_src(src_package, src_dir)
    deprec.install_from_src(src_package, src_dir)
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
  

  
  
  # XXX TODO
  # desc "backup repository" 
  # task :svn_backup_respository, :roles => :scm do
  #   puts "read http://svnbook.red-bean.com/nightly/en/svn-book.html#svn.reposadmin.maint.backup"
  # end

end
