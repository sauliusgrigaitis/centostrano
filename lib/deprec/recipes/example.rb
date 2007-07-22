Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :example do
      
      desc "Install example"
      task :install, :roles => :web do
      end
      
      desc "Generate configuration file(s) for XXX from template(s)"
      task :config_gen, :roles => :web do
      end
      
      desc 'Deploy configuration files(s) for XXX' 
      task :config, :roles => :web do
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