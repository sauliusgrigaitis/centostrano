# Copyright 2008 by Saulius Grigaitis. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  
  namespace :centos do
    namespace :merb do
        
      set :merb_servers, 2
      set :merb_port, 8000
      set(:merb_user) { mongrel_user + application }
      set :merb_group_prefix,  'app_'
      set(:merb_group) { merb_group_prefix + application }

      
      # Install 
      
      desc "Install merb"
      task :install, :roles => :app do
        install_deps
        %w(core plugins more).each do |gem|
          package_info = {
            :filename => "merb-#{gem}",   
            :dir => "merb-#{gem}",  
            :unpack => "git clone git://github.com/wycats/merb-#{gem}.git;"
          }     
          deprec2.unpack_src(package_info, src_dir)
          sudo "sh -c 'cd #{src_dir}/merb-#{gem}; rake install'"
        end
      end
     
      task :install_deps do
        top.centos.mongrel.install
        top.centos.git.install
        gem2.install(%w(rack mongrel json json_pure erubis mime-types rspec hpricot mocha rubigen haml markaby mailfactory ruby2ruby))
      end 

      
      # Control
=begin 
      desc "Start application server."
      task :start, :roles => :app do
        send(run_method, "/usr/local/bin/merb --user #{merb_user} --group #{merb_group} --daemonize --cluster-nodes #{merb_servers} --merb-root #{current_path} --port #{merb_port} -e production")
      end
      
      desc "Stop application server."
      task :stop, :roles => :app do
        send(run_method, "sh -c 'cd #{current_path} && merb -k all --merb-root'")
      end
      
      desc "Restart application server."
      task :restart, :roles => :app do
        top.centos.merb.stop
        top.centos.merb.start
      end
=end      
    end
  end
end
