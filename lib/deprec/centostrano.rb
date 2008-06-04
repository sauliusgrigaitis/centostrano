# Copyright 2008 by Saulius Grigaitis. All rights reserved.
require 'capistrano'
require 'fileutils'

module Yum

  def enable_repository(name)
    case name
    when :rpmforge
      rpm_install("http://dag.wieers.com/rpm/packages/rpmforge-release/rpmforge-release-0.3.6-1.el5.rf.`uname -i`.rpm")
    when :epel
      sudo "test -f /etc/yum.repos.d/epel.repo || rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-2.noarch.rpm"
    end
  end
  
  def rpm_install(packages, options={})
    send(run_method, "wget -Ncq #{[*packages].join(' ')}", options)
    files=[*packages].collect { |package| File.basename(package) }
    # TODO hmm... This should me replaces with something more smart, like check if package is already installed
    send(run_method, "rpm -i --force #{files.join(' ')}", options)
    send(run_method, "rm #{files.join(' ')}", options)
  end

  def install_from_src(src_package, src_dir)
    package_dir = File.join(src_dir, src_package[:dir])
    deprec2.unpack_src(src_package, src_dir)
    enable_repository :rpmforge
    enable_repository :epel
    rpm_install("http://www.asic-linux.com.mx/~izto/checkinstall/files/rpm/checkinstall-1.6.1-1.i386.rpm") 
    apt.install( {:base => %w(gcc gcc-c++ make patch rpm-build which)}, :stable )
    # XXX replace with invoke_command
    sudo <<-SUDO
    sh -c '
    cd #{package_dir};
    #{src_package[:configure]}
    #{src_package[:make]}
    /usr/local/sbin/checkinstall -y -R --install #{src_package[:install]}
    #{src_package[:post_install]}
    '
    SUDO
    #/usr/local/sbin/checkinstall --fstrans=no -y -R #{src_package[:install]}
  end

end

Capistrano.plugin :yum, Yum
