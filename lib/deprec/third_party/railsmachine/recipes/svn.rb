require 'fileutils'
Capistrano.configuration(:must_exist).load do
 
desc "create svn repository"
 task :svn_create_repos, :roles => :scm do
   svn_root ||= '/var/svn'
   scm_group ||= 'scm'
   deprec.groupadd('scm')
   deprec.add_user_to_group(user, scm_group)
   deprec.mkdir(svn_root, '2775', scm_group, user)
   sudo "svnadmin verify #{svn_root} || sudo svnadmin create #{svn_root}"
 end
 
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
 
end