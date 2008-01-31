# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  
  # deprecated tasks from deprec1
  # we're now using namespaces and some different naming conventions
  
  # XXX use deprecated function to generate these dynamically
  
  task :setup_admin_account do
    puts "The deprec task setup_admin_account has been deprecated."
    puts "Please use the replacement version deprec:users:add"
  end
  
  task :change_root_password do
    puts "The deprec task change_root_password has been deprecated."
    puts "Please use the replacement version deprec:users:passwd"
  end
  
end