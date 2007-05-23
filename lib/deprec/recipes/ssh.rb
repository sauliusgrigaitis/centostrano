Capistrano.configuration(:must_exist).load do

  # set :user, (defined?(user) ? user : ENV['USER'])
  desc "Copies contents of ssh public keys into authorized_keys file"
  task :setup_ssh_keys do
    
    unless ssh_options[:keys]  
      puts <<-ERROR

      You need to define the name of your SSH key(s)
      e.g. ssh_options[:keys] = %w(/Users/someuser/.ssh/id_dsa)

      You can put this in your .caprc file in your home directory.

      ERROR
      exit
    end
    
    sudo "test -d ~/.ssh || mkdir ~/.ssh"
    sudo "chmod 0700 ~/.ssh"    
    put(ssh_options[:keys].collect{|key| File.read(key+'.pub')}.join("\n"),
      File.join('/home', user, '.ssh/authorized_keys'),
      :mode => 0600 )
  end
  
end