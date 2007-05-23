
require 'capistrano'

module Deprec
  DEPREC_TEMPLATES_BASE = File.join(File.dirname(__FILE__), '..', 'recipes', 'templates')

  def render_template_to_file(template_name, destination_file_name, templates_dir = DEPREC_TEMPLATES_BASE)
    template_name += '.conf' if File.extname(template_name) == ''
    
    file = File.join(templates_dir, template_name)
    buffer = render :template => File.read(file)

    temporary_location = "/tmp/#{template_name}"
    put buffer, temporary_location
    sudo "cp #{temporary_location} #{destination_file_name}"
    delete temporary_location
  end
  
  def append_to_file_if_missing(filename, value, options={})
    # XXX sort out single quotes in 'value' - they'l break command!
    # XXX if options[:requires_sudo] and :use_sudo then use sudo
    sudo <<-END
    sh -c '
      grep "#{value}" #{filename} > /dev/null 2>&1 || 
      test ! -f #{filename} ||
      echo "#{value}" >> #{filename}
      '
    END
  end
  
  # ##
  # # Update a users crontab
  # #
  # # user: which users crontab should be affected
  # # entry: the entry as it would appear in the crontab (e.g. '*/15 * * * * sleep 5')
  # # action: :add or :remove
  # #
  # def update_user_crontab(user, entry, action = :add)
  #   # we don't want capistrano exiting if crontab doesn't yet exist 
  #   cur_crontab = capture "crontab -u #{user} -l || exit 0"
  #   if cur_crontab.include?(entry)
  #     if action == :remove
  #       sudo "crontab -u #{user} -l | grep -v #{entry} | sudo crontab -u #{user} -"
  #     end
  #   else
  #     if action == :add
  #       new_crontab = cur_crontab.chomp + entry
  #       puts new_crontab
  #       sudo "echo '#{new_crontab}' | sudo crontab -u #{user} -"
  #     end
  #   end
  # end

  
  # create new user account on target system
  def useradd(user, options={})
    options[:shell] ||= '/bin/bash' # new accounts on ubuntu 6.06.1 have been getting /bin/sh
    switches = ''
    switches += " --shell=#{options[:shell]} " if options[:shell]
    switches += ' --create-home ' unless options[:homedir] == false
    switches += " --gid #{options[:group]} " unless options[:group].nil?
    send(run_method, "grep '^#{user}:' /etc/passwd || sudo /usr/sbin/useradd #{switches} #{user}")
  end
  
  # create a new group on target system
  def groupadd(group)
    # XXX I don't like specifying the path to groupadd - need to sort out paths before long
    send(run_method, "grep '#{group}:' /etc/group || sudo /usr/sbin/groupadd #{group}")
  end
  
  # add group to the list of groups this user belongs to
  def add_user_to_group(user, group)
    send(run_method, "groups #{user} | grep ' #{group} ' || sudo /usr/sbin/usermod -G #{group} -a #{user}")
  end
  
  # create directory if it doesn't already exist
  # set permissions and ownership
  # XXX move mode, path and
  def mkdir(path, options={})
    options[:mode] ||= '0755'
    sudo "test -d #{path} || sudo mkdir -p -m#{options[:mode]} #{path}"
    sudo "chgrp -R #{options[:group]} #{path}" if options[:group]
    sudo "chown -R #{user} #{path}" if options[:user]
  end
  
  
  # download source package if we don't already have it
  def download_src(src_package, src_dir)
    deprec.groupadd(group)
    sudo "test -d #{src_dir} || sudo mkdir #{src_dir}" 
    sudo "chgrp -R #{group} #{src_dir}"
    sudo "chmod -R g+w #{src_dir}"
    # XXX check if file exists and if we have and MD5 hash or bytecount to compare against
    # XXX if so, compare and decide if we need to download again
    if defined?(src_package[:md5sum])
      md5_clause = " && echo '#{src_package[:md5sum]}' | md5sum -c - "
    end
    sudo <<-SUDO
    sh -c "cd #{src_dir} && test -f #{src_package[:file]} #{md5_clause} || wget --timestamping #{src_package[:url]}"
    SUDO
  end
  
  # unpack src and make it writable by the group
  def unpack_src(src_package, src_dir)
    package_dir = File.join(src_dir, src_package[:dir])
    sudo <<-SUDO
    sh -c '
      cd #{src_dir};
      test -d #{package_dir}.old && rm -fr #{package_dir}.old;
      test -d #{package_dir} && mv #{package_dir} #{package_dir}.old;
      #{src_package[:unpack]}
      chgrp -R #{group} #{package_dir};  
      chmod -R g+w #{package_dir};
    '
    SUDO
  end
  
  # install package from source
  def install_from_src(src_package, src_dir)
    package_dir = File.join(src_dir, src_package[:dir])
    unpack_src(src_package, src_dir)
    apt.install( {:base => %w(build-essential)}, :stable )
    sudo <<-SUDO
    sh -c '
      cd #{package_dir};
      #{src_package[:configure]}
      #{src_package[:make]}
      #{src_package[:install]}
      #{src_package[:post_install]}
      '
    SUDO
  end
  

end

Capistrano.plugin :deprec, Deprec