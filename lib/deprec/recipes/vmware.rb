Capistrano.configuration(:must_exist).load do
  set :vm_dir, '/var/vm'
  set :stemserver, 'stemserver_ubuntu_6.06.1'
  
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