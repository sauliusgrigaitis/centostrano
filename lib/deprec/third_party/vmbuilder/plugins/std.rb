# =std.rb: Capistrano Standard Methods
# Standard library of procedures and functions that you can use with Capistrano.
# 
# ----
# Copyright (c) 2006 Neil Wilson, Aldur Systems Ltd
#
# Licensed under the GNU Public License v2. No warranty is provided.

require 'capistrano'

# = Purpose
# Std is a Capistrano plugin that provides a set of standard methods refactored
# out of several Capistrano task libraries.
#
# Installs within Capistrano as the plugin _std_
#
# = Usage
#
#    require 'vmbuilder/plugins/std'
#
# Prefix all calls to the library with <tt>std.</tt>
module Std

  begin
    # Use the Mmap class if it is available
    # http://moulon.inra.fr/ruby/mmap.html    
    require 'mmap'
    MMAP=true #:nodoc:
  rescue LoadError
    # no MMAP class, use normal reads instead
    MMAP=false #:nodoc:
  end

  # Copies the files specified by +file_pattern+ to +destination+
  #
  # Error checking is minimal - a pattern onto a single file will result in +destination+
  # containing the data from the last file only.
  #
  # Installs via *sudo*,  +options+ are as for *put*.
  def fput(file_pattern, destination, options={})
    logger.info file_pattern
    Dir.glob(file_pattern) do |fname|
      logger.info fname
      if File.readable?(fname) then
	if MMAP
	  logger.debug "Using Memory Mapped File Upload"
	  fdata=Mmap.new(fname,"r", Mmap::MAP_SHARED, :advice => Mmap::MADV_SEQUENTIAL)
        else
	  fdata=File.open(fname).read
	end
	su_put(fdata, destination, File.join('/tmp',File.basename(fname)), options)
      end
    end
  end

  # Upload +data+ to +temporary_area+ before installing it in
  # +destination+ using sudo.
  #
  # +options+ are as for *put*
  #
  def su_put(data, destination, temporary_area='/tmp', options={})
    temporary_area = File.join(temporary_area,File.basename(destination)) if File.directory?(temporary_area)
    put(data, temporary_area, options)
    sudo <<-CMD
      sh -c "install -m#{sprintf("%3o",options[:mode]||0755)} #{temporary_area} #{destination} &&
      rm -f #{temporary_area}"
    CMD
  end
  
  # Copies the +file_pattern+, which is assumed to be a tar
  # file of some description (gzipped or plain), and unpacks it into
  # +destination+.
  def unzip(file_pattern, destination, options={})
    Dir.glob(file_pattern) do |fname|
      if File.readable?(fname) then
	target="/tmp/#{File.basename(fname)}"
	if MMAP
	  logger.debug "Using Memory Mapped File Upload"
	  fdata=Mmap.new(fname,"r", Mmap::MAP_SHARED, :advice => Mmap::MADV_SEQUENTIAL)
        else
	  fdata=File.open(fname).read
	end
	put(fdata, target, options)
	sudo <<-CMD
	  sh -c "cd #{destination} &&
	  zcat -f #{target} | tar xvf - &&
	  rm -f #{target}"
	CMD
      end
    end
  end
  
  # Creates the directory +web_root_dir+ using sudo is +use_sudo+ is true.
  #
  # Makes the root directory manageble by the +control_group+ group and sets the
  # permissions so that the directory is writeable by +control_group+ and the group
  # remains _sticky_
  #
  def create_web_root(web_root_dir, control_group)
    send run_method, <<-CMD
      sh -c "[ -d #{web_root_dir} ] || mkdir -m2770 -p #{web_root_dir}"
    CMD
    send(run_method, "chgrp -c #{control_group} #{web_root_dir}")
  end

  # Wrap this around your task calls to catch the no servers error and
  # ignore it
  #    
  #    std.ignore_no_servers_error do
  #      activate_mysql
  #    end
  #    
  def ignore_no_servers_error (&block)
    begin
      yield
    rescue RuntimeError => failure
      if failure.message =~ /no servers matched/
	logger.debug "Ignoring 'no servers matched' error in task #{current_task.name}"
      else
	raise
      end
    end
  end

  # Wrap this around your task to force a connection as root.
  #
  #    std.connect_as_root do
  #      install_sudo
  #    end
  #
  def connect_as_root (&block)
    begin
      tempuser = user
      set :user, "root"
      yield tempuser
    ensure
      set :user, tempuser if tempuser
    end
  end

  #Returns a random string of alphanumeric characters of size +size+
  #Useful for passwords, usernames and the like.
  def random_string(size=10)
    s = ""
    size.times { s << (i = rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
    s
  end

end

Capistrano.plugin :std, Std
#
# vim: nowrap sw=2 sts=2 ts=8 ff=unix ft=ruby:
