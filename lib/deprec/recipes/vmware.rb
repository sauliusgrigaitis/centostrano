Capistrano::Configuration.instance(:must_exist).load do 
  
  namespace :deprec do
    
    namespace :vmware_server do # XXX still needs testing

      set :vm_dir, '/var/vm'
      set :stemserver, 'stemserver_ubuntu_6.06.1'
  
      # task :install_my_package do
      #   packages = {:base => %w{build-essential libdb2 xinetd}}
      #   packages[:base] << 'linux-headers-$(uname -r)'
      #   apt.install(packages, :stable)
      # end
  
      task :install do
        version = 'VMware-server-1.0.1-29996'
        set :src_package, {
          :file => version + '.tar.gz',
          :dir => 'vmware-server-distrib',  
          :url => "http://10.0.100.45/download/vmware/#{version}.tar.gz",
          :unpack => "tar zxf #{version}.tar.gz;",
        }
        # pre-requisites on Ubuntu
        disable_cdrom_install
        enable_universe
        packages = {:base => %w{build-essential libdb2 xinetd}}
        packages[:base] << 'linux-headers-$(uname -r)'
        apt.install(packages, :stable)
    
    
        # sudo apt-get install build-essential x-window-system-core
    
        deprec.download_src(src_package, src_dir)
        deprec.install_from_src(src_package, src_dir)
        puts    
        puts "IMPORTANT"
        puts "manually run the following command:"
        puts "sudo /usr/bin/vmware-config.pl"
        puts
      end
    
      desc :install_deps do
        # packages = {:base => %w(build-essential xinetd
        #     libx11-6 libx11-dev libxtst6 xlibs-dev xinetd wget
        #     xinetd gcc binutils-doc cpp-doc make manpages-dev autoconf 
        #     automake1.9 libtool flex bison gdb gcc-doc
        # )}
        packages = {:base => %w{build-essential libdb2 xinetd}}
        apt.install( packages, :stable )
      end
      
    end
    

    namespace :vmware_mui do # XXX still needs testing

      task :install do
        version = 'VMware-mui-1.0.1-29996'
        src_package = {
          :file => version + '.tar.gz',
          :dir => 'vmware-mui-distrib',  
          :url => "http://10.0.100.45/download/vmware/#{version}.tar.gz",
          :unpack => "tar zxf #{version}.tar.gz;",
          :install => './vmware-install.pl;'
        }
        deprec.download_src(src_package, src_dir)
        deprec.unpack_src(src_package, src_dir)
        # XXX work out how to do this interactive through capistrano
        puts
        puts "IMPORTANT - you need to log in and run the following commands"
        puts "cd /usr/local/src/vmware-server-distrib && sudo ./vmware-install.pl"
        puts "cd /etc/vmware/ssl/ && sudo touch rui.key rui.crt"
        puts "sudo /usr/bin/vmware-config.pl"
        puts
      end
      
      desc :install_deps do
        # packages = {:base => %w(build-essential xinetd
        #     libx11-6 libx11-dev libxtst6 xlibs-dev xinetd wget
        #     xinetd gcc binutils-doc cpp-doc make manpages-dev autoconf 
        #     automake1.9 libtool flex bison gdb gcc-doc
        # )}
        packages = {:base => %w{build-essential libdb2 xinetd}}
        apt.install( packages, :stable )
      end
      
      task :activate, :roles => :vmhost do
        sudo "update-rc.d -f httpd.vmware defaults"
      end

      task :deactivate, :roles => :vmhost do
        sudo "update-rc.d -f httpd.vmware remove"
      end
    end
    
    
    namespace :vmware_tools do

      task :install do
        
        puts <<-HEREDOC
        
        You need to mount the VMware tools. On the VMware host run the command
        either from the 'VM' menu on the graphical console or by using commands 
        like the following:
        
        mbailey@sm01:~$ vmrun list
        Total running VMs: 1
        /var/vm/embryo/u710x86/Ubuntu.vmx
        mbailey@sm01:~$ vmrun installtools /var/vm/embryo/u710x86/Ubuntu.vmx
        HEREDOC
        
        Capistrano::CLI.ui.ask "hit enter when done"
        
        install_deps
        # http://ubuntu-tutorials.com/2007/10/02/how-to-install-vmware-tools-on-ubuntu-guests/
        sudo "mount -l | grep cdrom || sudo mount /cdrom"
        sudo "sh -c 'cd #{src_dir} && tar -xzf /cdrom/VMwareTools*.gz'"
        puts <<-HEREDOC
        OK, now you have to run this on VMware guest via local console shell: 
        
          cd #{src_dir}/vmware-tools-distrib/
          sudo ./vmware-install.pl
          
        HEREDOC
      end
      
      task :install_deps do
        apt.install( {:base => ['build-essential', 'linux-headers-$(uname -r)']}, :stable )
      end
      
    end
    
  end
end
  
  
# task :replicate_stemserver do
#   sudo <<-SUDO
#   sh -c '
#   cd #{vm_dir};
#   test -d #{stemserver} || tar zxfv #{stemserver}.tgz;
#   perl -pi -e 's/displayName = ".*"/displayName = "#{new_hostname}"/' stemserver/*.vmx;
#   mv stemserver #{new_hostname};
#   SUDO
# end
# 
# desc "update hostname and ip address of new virtual server"
# task :differentiate_stemserver do
#   # 
#   
#   # update /etc/hostname
#   # update /etc/hostname
#   # update /etc/network/interfaces
#   
# end