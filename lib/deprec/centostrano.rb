# Copyright 2008 by Saulius Grigaitis. All rights reserved.
require 'capistrano'
require 'fileutils'

module Centostrano

  def install_from_src(src_package, src_dir)
    package_dir = File.join(src_dir, src_package[:dir])
    unpack_src(src_package, src_dir)
    apt.install( {:base => %w(gcc gcc-c++ make checkinstall)}, :stable )
    # XXX replace with invoke_command
    sudo <<-SUDO
    sh -c '
    cd #{package_dir};
    #{src_package[:configure]}
    checkinstall #{src_package[:make]}
    #{src_package[:install]}
    #{src_package[:post_install]}
    '
    SUDO
  end

end

Capistrano.plugin :centostrano, Centostrano
