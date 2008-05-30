# Copyright 2008 by Saulius Grigaitis. All rights reserved.
require 'capistrano'
require 'fileutils'

module Yum

  def enable_rpmforge_repository
      rpm_install("http://dag.wieers.com/rpm/packages/rpmforge-release/rpmforge-release-0.3.6-1.el5.rf.`uname -i`.rpm")
  end
  
  def rpm_install(packages, options={})
    send(run_method, "wget -Ncq #{[*packages].join(' ')}", options)
    files=[*packages].collect { |package| File.basename(package) }
    send(run_method, "rpm -i --force #{files.join(' ')}", options)
    send(run_method, "rm #{files.join(' ')}", options)
  end

  def install_from_src(src_package, src_dir)
    package_dir = File.join(src_dir, src_package[:dir])
    deprec2.unpack_src(src_package, src_dir)
    enable_rpmforge_repository
    #rpm_install("http://www.asic-linux.com.mx/~izto/checkinstall/files/rpm/checkinstall-1.6.1-1.i386.rpm") 
    sudo "sh -c 'echo \"echo \'/bin/rpm\'\" > /usr/bin/which; chmod 755 /usr/bin/which'"
    apt.install( {:base => %w(gcc gcc-c++ make patch rpm-build checkinstall)}, :stable )
    # XXX replace with invoke_command
    sudo <<-SUDO
    sh -c '
    cd #{package_dir};
    #{src_package[:configure]}
    #{src_package[:make]}
    /usr/sbin/checkinstall -y -R -fstrans=no #{src_package[:install]}
    #{src_package[:post_install]}
    '
    SUDO
    #/usr/local/sbin/checkinstall --fstrans=no -y -R #{src_package[:install]}
  end

end

Capistrano.plugin :yum, Yum
