Capistrano::Configuration.instance(:must_exist).load do 
  # XXX not complete
  namespace :deprec do
    namespace :postfix do
      
      desc "Install example"
      task :install, :roles => :web do
        install_deps
      end
      
      task :install_deps do
        apt.install( {:base => %w(build-essential postfix)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:postfix] = [
        
        {:template => "example.conf.erb",
         :path => '/etc/example/example.conf',
         :mode => '0755',
         :owner => 'root:root'}
         
      ]
      
      desc "Generate configuration file(s) for XXX from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:postfix].each do |file|
          deprec2.render_template(:postfix, file)
        end
      end
      
      desc 'Deploy configuration files(s) for XXX' 
      task :config, :roles => :mail do
        deprec2.push_configs(:postfix, SYSTEM_CONFIG_FILES[:postfix])
      end
      
      task :start, :roles => :web do
      end
      
      task :stop, :roles => :web do
      end
      
      task :restart, :roles => :web do
      end
      
      task :activate, :roles => :web do
      end  
      
      task :deactivate, :roles => :web do
      end
      
      task :backup, :roles => :web do
      end
      
      task :restore, :roles => :web do
      end
      
    end
  end
end
      
      
      # Capistrano::Configuration.instance(:must_exist).load do 
# 
#   namespace :deprec do namespace :nginx do
#       
#   #Craig: I've kept this generic rather than calling the task setup postfix. 
#   # if people want other smtp servers, it could be configurable
#   desc "install and configure postfix"
#   task :setup_smtp_server do
#     install_postfix
#     set :postfix_destination_domains, [domain] + apache_server_aliases
#     deprec.render_template_to_file('postfix_main', '/etc/postfix/main.cf')
#   end
# 
#   end end
# end