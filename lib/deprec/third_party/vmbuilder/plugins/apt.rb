# =apt.rb: Debian 'apt' Installer library
# Capistrano task library to install and manage apt packages
#
# ----
# Copyright (c) 2006 Neil Wilson, Aldur Systems Ltd
#
# Licensed under the GNU Public License v2. No warranty is provided.

require 'capistrano'

# = Purpose
# Apt is a Capistrano plugin module providing a set of methods
# that invoke the *apt* package manager (as used in Debian and Ubuntu)
#
# Installs within Capistrano as the plugin _apt_.
#
# =Usage
#    
#    require 'vmbuilder/plugins/apt'
#
# Prefix all calls to the library with <tt>apt.</tt>
#
module Apt 

  # Default apt-get command - reduces any interactivity to the minimum.
  APT_GET="DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive apt-get" 

  # Default list of packages required to extract source packages.
  BACKPORT_REQUIRED={:base => %w(dpkg-dev debhelper devscripts fakeroot)}

  # Directory where any package compilation takes place.
  BUILD_DIR="/var/cache/backport/build"

  # Run the apt install program across the package list in 'packages'. 
  # Select those packages referenced by <tt>:base</tt> and the +version+
  # of the distribution you want to use.
  def install(packages, version, options={})
    special_options="--allow-unauthenticated" if version != :stable
    cmd = <<-CMD
    sh -c "#{APT_GET} -qyu #{special_options.to_s} install #{package_list(packages, version)}"
    CMD
    sudo(cmd, options)
  end

  # Run an apt autoclean
  def autoclean(options={})
    cmd = <<-CMD
      sh -c "#{APT_GET} -qy autoclean"
    CMD
    sudo(cmd, options)
  end

  # Run an apt distribution upgrade
  def dist_upgrade(options={})
    cmd = <<-CMD
      sh -c "#{APT_GET} -qy dist-upgrade"
    CMD
    sudo(cmd, options)
  end

  # Run an apt upgrade. Use dist_upgrade instead if you want to upgrade
  # the critical base packages.
  def upgrade(options={})
    cmd = <<-CMD
      sh -c "#{APT_GET} -qy upgrade"
    CMD
    sudo(cmd, options)
  end

  # Run an apt update.
  def update(options={})
    cmd = <<-CMD
      sh -c "#{APT_GET} -qy update"
    CMD
    sudo(cmd, options)
  end

  # Update the apt control files using the files from the machine
  # which is running Capistrano. Set the default version to +version+
  def update_apt(version, myopts={})
    apt_fname="/etc/apt/apt.conf"
    sources_fname="/etc/apt/sources.list"
    pref_fname="/etc/apt/preferences"
    std.su_put("APT::Default-Release \"#{version.to_s}\";\n"+apt_conf, apt_fname, "/tmp", myopts)
    std.su_put(sources, sources_fname, "/tmp", myopts)
    std.su_put(preferences, pref_fname, '/tmp', myopts) 
  end

  # Downloads the specified source module and the quoted dependencies 
  # Compiles the module and installs it.
  #
  # If no dependencies are specified, runs an apt build-dep on the stable
  # package list in an attempt to locate them automatically.
  # 
  # Alter the <tt>deb-src</tt> line in <tt>sources.list</tt> file to
  # determine which distribution source files are retrieved from.
  def backport_to_stable(packages, dependencies={})
    install(BACKPORT_REQUIRED, :stable)
    if dependencies.empty?
      sudo <<-CMD
	sh -c "#{APT_GET} -qyu build-dep #{package_list(packages, :stable)}"
      CMD
    else
      install(dependencies, :stable)
    end
    patch_gcc
    sudo <<-SUDO
      sh -c "[ -d #{BUILD_DIR} ] || { mkdir -p #{BUILD_DIR} && chown #{user || ENV['USER']} #{BUILD_DIR}; }"
    SUDO
    sudo <<-CMD
      sh -c "cd #{BUILD_DIR} &&
      if [ ! -f `apt-get --print-uris source #{package_list(packages, :stable)}| tail -n1 | cut -d' ' -f2` ]; then
	#{APT_GET} -qyub source #{package_list(packages, :stable)};
      fi;"
    CMD
    sudo "dpkg -i #{BUILD_DIR}/*.deb"
  end

  # Boot script manipulation command
  def rc_conf(packages, setting)
    packages.each do |service|
      sudo "sysv-rc-conf --level 2 #{service} #{setting}"
    end
  end

private

  # Provides a string containing all the package names in the base
  #list plus those in +version+.
  def package_list(packages, version)
    packages[:base].to_a.join(' ') + ' ' + packages[version].to_a.join(' ')
  end

  # Stable likes to use gcc3.3. Force it to use 3.4 if it is installed.
  def patch_gcc
    sudo <<-CMD
      sh -c "[ ! -f /usr/bin/gcc-3.4 ] || ln -sf /usr/bin/gcc-3.4 /usr/local/bin/gcc"
    CMD
  end

end

Capistrano.plugin :apt, Apt
# vim: nowrap sw=2 sts=2 ts=8 ff=unix ft=ruby:
