Capistrano::Configuration.instance(:must_exist).load do 
  
  # require 'deprec/third_party/vmbuilder/plugins/apt'

  # Package files for a rails  machine
  set :rails_ubuntu, {
  :base => %w(build-essential ntp-server mysql-server wget
              ruby irb ri rdoc ruby1.8-dev libopenssl-ruby libmysql-ruby 
              zlib1g-dev zlib1g openssl libssl-dev)
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
  
  desc "enable multiverse repositories"
  task :enable_multiverse do
    # ruby is not installed by default or else we'd use 
    # sudo "ruby -pi.bak -e \"gsub(/#\s?(.*universe$)/, '\1')\" sources.list"
    sudo 'perl -pi -e \'s/#\s?(deb.* multiverse$)/\1/g\' /etc/apt/sources.list'
    apt.update
  end
  
  desc "disable universe repositories"
  task :disable_multiverse do
    # ruby is not installed by default or else we'd use 
    # sudo "ruby -pi.bak -e \"gsub(/#\s?(.*universe$)/, '\1')\" sources.list"
    sudo 'perl -pi -e \'s/^([^#]*multiverse)/#\1/g\' /etc/apt/sources.list'
    apt.update
  end
  
  desc "disable cdrom as a source of packages"
  task :disable_cdrom_install do
    # ruby is not installed by default so we use perl
    sudo 'perl -pi -e \'s/^([^#]*deb cdrom)/#\1/g\' /etc/apt/sources.list'
    apt.update
  end
  
  # XXX we need to run 'sudo apt-cdrom' to add a cdrom
  # desc "enable cdrom as a source of packages"
  # task :enable_cdrom_install do
  #   # ruby is not installed by default so we use perl
  #   sudo 'perl -pi -e \'s/^[# ]*(deb cdrom)/\1/g\' /etc/apt/sources.list'
  #   apt.update
  # end
  
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

  # XXX write function to enable/disable a service
  # XXX update-rc.d lighttpd remove
  # XXX update-rc.d -n httpd defaults
  
  
end