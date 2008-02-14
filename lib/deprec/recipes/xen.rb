# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :xen do
      
      # ref: http://www.eadz.co.nz/blog/article/xen-gutsy.html
      
      SYSTEM_CONFIG_FILES[:xen] = [
                
        {:template => "xend-config.sxp.erb",
        :path => '/etc/xen/xend-config.sxp',
        :mode => 0644,
        :owner => 'root:root'},
        
        {:template => "xen-tools.conf.erb",
         :path => '/etc/xen-tools/xen-tools.conf',
         :mode => 0644,
         :owner => 'root:root'},
         
        {:template => "xm.tmpl.erb",
         :path => '/etc/xen-tools/xm.tmpl',
         :mode => 0644,
         :owner => 'root:root'},
         
        {:template => "xendomains.erb",
         :path => '/etc/default/xendomains',
         :mode => 0755,
         :owner => 'root:root'},
         
         # This one is a bugfix for gutsy 
        {:template => "15-disable-hwclock",
         :path => '/usr/lib/xen-tools/gutsy.d/15-disable-hwclock',
         :mode => 0755,
         :owner => 'root:root'},
         
        # So is this - xendomains fails to shut down domains on system shutdown
        {:template => "xend-init.erb",
         :path => '/etc/init.d/xend',
         :mode => 0755,
         :owner => 'root:root'},
          
        # This gives you a second network bridge on second ethernet device  
        {:template => "network-bridge-wrapper",
         :path => '/etc/xen/scripts/network-bridge-wrapper',
         :mode => 0755,
         :owner => 'root:root'}
         
      ]
      
      desc "Install Xen"
      task :install, :roles => :dom0 do
        install_deps
        # it's all in deps baby
      end
      
      task :install_deps do
        # for amd64 version of ubuntu 7.10
        apt.install( {:base => %w(linux-image-xen bridge-utils libxen3.1 python-xen-3.1 xen-docs-3.1 xen-hypervisor-3.1 xen-ioemu-3.1 xen-tools xen-utils-3.1 lvm2)}, :stable )
        # alternatively, for x86 version of ubuntu:
        # apt-get install ubuntu-xen-server libc6-xen    
      end
      
      desc "Generate configuration file(s) for Xen from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:xen].each do |file|
          deprec2.render_template(:xen, file)
        end
      end
      
      desc "Push Xen config files to server"
      task :config, :roles => :dom0 do
        deprec2.push_configs(:xen, SYSTEM_CONFIG_FILES[:xen])
      end
      
      # Create new virtual machine
      # xen-create-image --force --ip=192.168.1.31 --hostname=x1 --mac=00:16:3E:11:12:31
      
      # Start a virtual image (and open console to it)
      # xm create -c /etc/xen/x1.cfg
      
    end
  end
end

# Stop the 'incrementing ethX problem'
#
# Ubuntu stores the MAC addresses of the NICs it sees. If you change an ethernet card (real or virtual)
# it will assign is a new ethX address. That's why you'll sometimes find eth2 but no eth1.
# Your domU's should have a MAC address assigned in their config file but if you come across this problem, 
# fix it with this:
#
# sudo rm /etc/udev/rules.d/70-persistent-net.rules