Capistrano.configuration(:must_exist).load do
  
  # require 'deprec/third_party/vmbuilder/plugins/apt'

  # Package files for a rails  machine
  set :rails_ubuntu, {
  :base => %w(build-essential ntp-server mysql-server wget
              ruby irb ri rdoc ruby1.8-dev libmysql-ruby 
              zlib1g-dev zlib1g openssl libssl-dev subversion)
  }
  
  desc "enable universe repositories"
  task :enable_universe do
    # ruby is not installed by default or else we'd use 
    # sudo "ruby -pi.bak -e \"gsub(/#\s?(.*universe$)/, '\1')\" sources.list"
    sudo 'perl -pi -e \'s/#\s?(.*dapper universe$)/\1/g\' /etc/apt/sources.list'
    apt.update
  end
  
  desc "disable universe repositories"
  task :disable_universe do
    # ruby is not installed by default or else we'd use 
    # sudo "ruby -pi.bak -e \"gsub(/#\s?(.*universe$)/, '\1')\" sources.list"
    sudo 'perl -pi -e \'s/^([^#]*dapper universe)/#\1/g\' /etc/apt/sources.list'
    apt.update
  end
  
  desc "disable cdrom as a source of packages"
  task :disable_cdrom_install do
    # ruby is not installed by default so we use perl
    sudo 'perl -pi -e \'s/^([^#]*deb cdrom)/#\1/g\' /etc/apt/sources.list'
    apt.update
  end
  
  desc "enable cdrom as a source of packages"
  task :enable_cdrom_install do
    # ruby is not installed by default so we use perl
    sudo 'perl -pi -e \'s/^[# ]*(deb cdrom)/\1/g\' /etc/apt/sources.list'
    apt.update
  end
  
  desc "installs packages required for a rails box"
  task :install_packages_for_rails do
    apt.install(rails_ubuntu, :stable)  # install packages for rails box   
  end
  
  desc "installs image magick packages"
  task :install_image_magic do
    apt.install({:base => ['imagemagick', 'libmagick9-dev']}, :stable)
  end
  
  desc "install postfix and dependent packages"
  task :install_postfix do
    apt.install({:base => ['postfix']}, :stable)
  end
  
  desc "write network config to server"
  task :network_configure do
    # set :ethernet_interfaces,  [{
    #                        :num => 0, 
    #                        :type => 'static', 
    #                        :ipaddr => '10.0.100.125', 
    #                        :netmask => '255.255.255.0',
    #                        :gateway => '10.0.100.1',
    #                        :dns1 => '203.8.183.1',
    #                        :dns2 => '4.2.2.1'
    #                        }]
                          
    deprec.render_template_to_file('interfaces.rhtml', '/etc/network/interfaces')
  end
  
  # desc "configure hostname on server"
  # task :hostname_configure do
  #   # update /etc/hostname
  #   # update /etc/hosts
  # end
  
  
  
  # XXX write function to enable/disable a service
  # XXX update-rc.d lighttpd remove
  # XXX update-rc.d -n httpd defaults
  
  
end