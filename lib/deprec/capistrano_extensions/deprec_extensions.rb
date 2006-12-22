
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
      grep '#{value}' #{filename} > /dev/null 2>&1 || 
      test ! -f #{filename} ||
      echo '#{value}' >> #{filename}
    END
  end
  
  # create new user account on target system
  def useradd(user)
    puts run_method
    send(run_method, "grep '^#{user}:' /etc/passwd || /usr/sbin/useradd -m #{user}")
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
  
  # download source package if we don't already have it
  def download_src(src_package, src_dir)
    deprec.groupadd(group)
    sudo "test -d #{src_dir} || sudo mkdir #{src_dir}" 
    sudo "chgrp -R #{group} #{src_dir}"
    sudo "chmod -R g+w #{src_dir}"
    # XXX check if file exists and if we have and MD5 hash or bytecount to compare against
    # XXX if so, compare and decide if we need to download again
    sudo "sh -c 'cd #{src_dir} && test -f #{src_package[:file]} || wget #{src_package[:url]}'"
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