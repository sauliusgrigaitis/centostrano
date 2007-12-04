Capistrano::Configuration.instance(:must_exist).load do 
    
  set :vm_dir, '/var/vm'
  
  namespace :deprec do
    
    namespace :vmware_server do # XXX still needs testing
  
      desc "This is a bit dodgy as it only works on ubuntu 7.10 server amd64"
      task :install do
        
        SRC_PACKAGES[:vmware_server] = {
          :filename => 'VMware-server-1.0.4-56528.tar.gz',   
          :md5sum => "60ec55cd66b77fb202d88bee79baebdf  VMware-server-1.0.4-56528.tar.gz", 
          :dir => 'vmware-server-distrib',  
          :url => "needs to be copied manually to /usr/local/src",
          :unpack => "tar zxf VMware-server-1.0.4-56528.tar.gz;"        }
        
        install_deps
        deprec2.download_src(SRC_PACKAGES[:vmware_server], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:vmware_server], src_dir)
        
        puts    
        puts "IMPORTANT"
        puts "manually run the following commands:"
        puts "sudo aptitude install ia32-libs # if you're using amd64 version of ubuntu"
        puts "cd #{src_dir}/vmware-server-distrib"
        puts "sudo ./vmware-install.pl;"
        puts "sudo /usr/bin/vmware-config.pl"
        puts
      end
    
      task :install_deps do
        enable_universe
        
        # packages = {:base => %w{build-essential libdb2 xinetd}}
        # packages[:base] << 'linux-headers-$(uname -r)'
        # apt.install(packages, :stable)
        
        # sudo apt-get install build-essential x-window-system-core
        
        # packages = {:base => %w(build-essential xinetd
        #     libx11-6 libx11-dev libxtst6 xlibs-dev xinetd wget
        #     xinetd gcc binutils-doc cpp-doc make manpages-dev autoconf 
        #     automake1.9 libtool flex bison gdb gcc-doc
        # )}
        
        # gutsy?
        #
        # sudo "apt-get install linux-headers-`uname -r` build-essential xinetd"
        # sudo aptitude install libx11-6 libx11-dev libxtst6 xlibs-dev xinetd wget
        # sudo aptitude install linux-headers-`uname -r` build-essential
        # sudo aptitude install xinetd ia32-libs
        # sudo aptitude install gcc binutils-doc cpp-doc make manpages-dev autoconf 
        # sudo aptitude install automake1.9 libtool flex bison gdb gcc-doc
        
        packages = {:base => %w{build-essential xinetd x-window-system-core}}
        packages[:base] << 'linux-headers-$(uname -r)'
        apt.install( packages, :stable )
      end
      
    end
    

    namespace :vmware_mui do # XXX still needs testing

      task :install do
        
        SRC_PACKAGES[:vmware_mui] = {
          :filename => 'VMware-mui-1.0.4-56528.tar.gz',   
          :md5sum => "6b13063d8ea83c2280549d33da92c476  VMware-mui-1.0.4-56528.tar.gz", 
          :dir => 'vmware-server-distrib',  
          :url => "needs to be copied manually to /usr/local/src",
          :unpack => "tar zxf VMware-mui-1.0.4-56528.tar.gz;"        
        }
        
        install_deps
        deprec2.download_src(SRC_PACKAGES[:vmware_mui], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:vmware_mui], src_dir)
        
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
        
        # not sure we need this
        # packages = {:base => %w{build-essential libdb2 xinetd}}
        # apt.install( packages, :stable )
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