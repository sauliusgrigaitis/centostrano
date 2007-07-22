Capistrano::Configuration.instance(:must_exist).load do 
  
  # deprecated tasks from deprec1
  # we're now using namespaces and some different naming conventions
  
  # XXX use deprecated function to generate these dynamically
  
  task :setup_admin_account do
    puts "The deprec task setup_admin_account has been deprecated."
    puts "Please use the replacement version deprec:users:add_admin"
  end
  
  task :setup_admin_account_as_root do
    puts "The deprec task setup_admin_account_as_root has been deprecated."
    puts "Please use the replacement version deprec:users:add_admin_as_root"
  end
  
  task :change_root_password do
    puts "The deprec task change_root_password has been deprecated."
    puts "Please use the replacement version deprec:users:passwd"
  end
  
  task :change_root_password_as_root do
    puts "The deprec task change_root_password_as_root has been deprecated."
    puts "Please use the replacement version deprec:users:passwd_as_root"
  end
  
end