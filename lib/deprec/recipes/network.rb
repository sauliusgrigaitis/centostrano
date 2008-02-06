# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :network do
      
      set(:hostname) { 
        Capistrano::CLI.ui.ask "hostname" do |q|
          # q.validate = /add hostname validation here/
        end 
      } 
      set(:eth0_ip) { 
        Capistrano::CLI.ui.ask "eth0 ip address" do |q|
          # q.validate = /add ip addr validation here/
        end 
      }
      set(:eth1_ip) { 
        Capistrano::CLI.ui.ask "eth1 ip address" do |q|
          # q.validate = /add ip addr validation here/
        end 
      }
      
      SYSTEM_CONFIG_FILES[:network] = [

        {:template => "interfaces.erb",
          :path => '/etc/network/interfaces',
          :mode => 0644,
          :owner => 'root:root'},

        {:template => "hosts.erb",
         :path => '/etc/hosts',
         :mode => 0644,
         :owner => 'root:root'},

        {:template => "hostname.erb",
         :path => '/etc/hostname',
         :mode => 0644,
         :owner => 'root:root'}
    
       ]
      
      desc "Update system networking configuration"
      task :config, :roles => :vmgz do
        SYSTEM_CONFIG_FILES[:network].each do |file|
          deprec2.render_template(:network, file.merge(:remote=>true))
        end
      end
      
      desc "Restart network interface"
      task :restart, :roles => :vmgz do
        sudo '/etc/init.d/networking restart'
      end
      
      
    end
  end
  
end