Capistrano::Configuration.instance(:must_exist).load do 
  
  # server specific tasks don't get linked into the canonical ones till runtime
  # So these stubs are for cap -T
  %w(web app db).each do |server|
    namespace "deprec:#{server}" do
      
      desc "Install #{server} server"
      task :install, :roles => server do 
      end
      
      desc "Generate config file(s) for #{server} server from template(s)"
      task :config_gen, :roles => server do
      end
      
      desc "Deploy configuration files(s) for #{server} server"
      task :config, :roles => server do
      end
      
      desc "Start #{server} server"
      task :start, :roles => server do
      end
      
      desc "Stop #{server} server"
      task :stop, :roles => server do
      end
      
      desc "Stop #{server} server"
      task :restart, :roles => server do
      end
      
      desc "Enable startup script for #{server} server"
      task :activate, :roles => server do
      end  
      
      desc "Disable startup script for #{server} server"
      task :deactivate, :roles => server do
      end
      
      desc "Backup data for #{server} server"
      task :backup, :roles => server do
      end
      
      desc "Restore data for #{server} server from backup"
      task :restore, :roles => server do
      end
      
    end
  end
end