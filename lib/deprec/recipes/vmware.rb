Capistrano.configuration(:must_exist).load do
  set :vm_dir, '/var/vm'
  set :stemserver, 'stemserver_ubuntu_6.06.1'
  
  # currently only for CentOS
  task :install_vmware_server do
    version = 'VMware-server-1.0.1-29996.i386'
    set :src_package, {
      :file => version + '.rpm',
      :url => "http://10.0.100.45/download/vmware/#{version}.rpm",
      :install => "rpm -i #{File.join(src_dir, version + '.rpm')};"
    }
    deprec.download_src(src_package, src_dir)
    sudo src_package[:install]
    sudo "yum install gcc" # when you select the develpment packages on CentOS it doesn't give you gcc!
    # XXX work out how to do this interactive through capistrano
    puts
    puts "IMPORTANT"
    puts "sudo /usr/bin/vmware-config.pl"
    puts
  end
  
  task :install_vmware_mui do
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
    puts "IMPORTANT - you need to log in and run"
    puts "cd /usr/local/src/vmware-mui-distrib && sudo ./vmware-install.pl"
    puts
  end
  
  task :replicate_stemserver do
    sudo <<-SUDO
    sh -c '
    cd #{vm_dir};
    test -d #{stemserver} || tar zxfv #{stemserver}.tgz;
    perl -pi -e 's/displayName = ".*"/displayName = "#{new_hostname}"/' stemserver/*.vmx;
    mv stemserver #{new_hostname};
    SUDO
  end

end