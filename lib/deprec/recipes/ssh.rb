Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ssh do

      desc "Sets up authorized_keys file on remote server"
      task :setup_keys do
        unless ssh_options[:keys]  
          puts <<-ERROR

          You need to define the name of your SSH key(s)
          e.g. ssh_options[:keys] = %w(/Users/someuser/.ssh/id_rsa)

          You can put this in your .caprc file in your home directory.

          ERROR
          exit
        end
    
        deprec2.mkdir '~/.ssh', :mode => '0700'
        put(ssh_options[:keys].collect{|key| File.read(key+'.pub')}.join("\n"),
          File.join('/home', user, '.ssh/authorized_keys'),
          :mode => 0600 )
      end      
    end
  end
end