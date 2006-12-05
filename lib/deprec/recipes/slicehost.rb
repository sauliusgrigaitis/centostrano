
Capistrano.configuration(:must_exist).load do

  # task :install_rails_stack_slicehost do
  #   std.connect_as_root do |tempuser|
  #     run "useradd -m #{tempuser}"
  #     deprec.append_to_file_if_missing('/etc/sudoers', '%admin ALL=(ALL) ALL')
  #     run "usermod --groups admin -a #{user}"
  #     # XXX do some interactive magic to get password
  #     # setup user password
  #     # Capistrano::CLI.password_prompt('SVN Password: ')
  #   end
  # end
  
  # desc "this should not appear in show tasks"
  # task :foo do
  #    # deprec.append_to_file_if_missing('/tmp/lala', "mike", options={})
  #    run "passwd"
  # end
  
end

