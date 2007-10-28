Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :user do
      
      desc "Create user account"
      task :add do
        target_user = Capistrano::CLI.ui.ask "Enter userid for new user" do |q|
          q.default = user
        end
        deprec2.useradd(target_user, :shell => '/bin/bash')
        puts "Setting password for new account"
        deprec2.invoke_with_input("passwd #{target_user}", /UNIX password/)
      end
      
      desc "Create admin account"
      task :add_admin do
        target_user = Capistrano::CLI.ui.ask "Enter userid for new user" 
        deprec2.useradd(target_user, :shell => '/bin/bash')
        puts "Setting pasword for new account"
        deprec2.invoke_with_input("passwd #{target_user}", /UNIX password/)
        deprec2.groupadd('admin')
        deprec2.add_user_to_group(target_user, 'admin')
        deprec2.append_to_file_if_missing('/etc/sudoers', '%admin ALL=(ALL) ALL')
      end
      
      desc "Create admin user (as root)"
      task :add_admin_as_root do
        deprec2.as_root { add_admin }
      end
  
      desc "Change user password"
      task :passwd do
        target_user = Capistrano::CLI.ui.ask "Enter user to change password for" do |q|
          q.default = user if user.is_a?(String)
        end
        deprec2.invoke_with_input("passwd #{target_user}", /UNIX password/) 
      end
      
      desc "Change user password (as root)"
      task :passwd_as_root do
        deprec2.as_root { passwd }
      end
      
      # desc "Create group"
      # task :add_group do
      #   target_group = Capistrano::CLI.ui.ask "Enter name for new group" 
      #   deprec2.groupadd(target_group)
      # end
      # 
      # desc "Add user to group"
      # task :add_user_to_group do
      #   # XXX not yet implemented
      # end

    end
  end
end