Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ssh do
      
      SYSTEM_CONFIG_FILES[:ssh] = [
        
        {:template => "sshd_config.erb",
         :path => '/etc/ssh/sshd_config_foo',
         :mode => '0644',
         :owner => 'root:root'}
      ]
      
      task :config_gen do        
        SYSTEM_CONFIG_FILES[:ssh].each do |file|
          deprec2.render_template(:ssh, file)
        end
      end
      
      desc "Push apache config files to server"
      task :config do
        deprec2.push_configs(:ssh, SYSTEM_CONFIG_FILES[:ssh])
      end

      desc "Sets up authorized_keys file on remote server"
      task :setup_keys do
        unless ssh_options[:keys]  
          puts <<-ERROR

          You need to define the name of your SSH key(s)
          e.g. ssh_options[:keys] = %w(/Users/your_username/.ssh/id_rsa)

          You can put this in your .caprc file in your home directory.

          ERROR
          exit
        end
        
        deprec2.mkdir '.ssh', :mode => '0700'
        put(ssh_options[:keys].collect{|key| File.read(key+'.pub')}.join("\n"),
          '.ssh/authorized_keys', :mode => 0600 )
      end      
    end
  end
end