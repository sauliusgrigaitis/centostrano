Capistrano.configuration(:must_exist).load do

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

end
