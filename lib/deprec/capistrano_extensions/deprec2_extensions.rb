require 'capistrano'

# DEPREC_TEMPLATES_BASE = File.join(File.dirname(__FILE__), '..', 'templates')

module Deprec2
  DEPREC_TEMPLATES_BASE = File.join(File.dirname(__FILE__), '..', 'templates')
  @@template_dir = File.join(File.dirname(__FILE__), '..', 'templates')

  # Render template (usually a config file) 
  # 
  # Usually we render it to a file on the local filesystem.
  # This way, we keep a copy of the config file under source control.
  # We can make manual changes if required and push to new hosts.
  #
  # If the options hash contains :path then it's written to that path.
  # If it contains :remote => true, the file will instead be written to remote targets
  # If options[:path] and options[:remote] are missing, it just returns the rendered
  # template as a string (good for debugging).
  #
  #  XXX I would like to get rid of :render_template_to_file
  #  XXX Perhaps pass an option to this function to write to remote
  #
  def render_template(app, options={})
    template = options[:template]
    path = options[:path] || nil
    remote = options[:remote] || false
    mode = options[:mode] || 0755
    owner = options[:owner] || nil
  
    # replace this with a check for the file
    if ! template
      puts "render_template() requires a value for the template!"
      return false 
    end
  
    template = ERB.new(IO.read(File.join(DEPREC_TEMPLATES_BASE, app.to_s, template)))
    rendered_template = template.result(binding)
  
    if remote 
      # render to remote machine
      puts 'You need to specify a path to render the template to!' unless path
      exit unless path
      sudo "test -d #{File.dirname(path)} || sudo mkdir -p #{File.dirname(path)}"
      std.su_put rendered_template, path, '/tmp/', :mode => mode.to_i
      sudo "chown #{owner} #{path}" if defined?(owner)
    elsif path 
      # render to local file
      full_path = File.join('config', app.to_s, path)
      path_dir = File.dirname(full_path)
      if File.exists?(full_path)
        puts
        puts "About to write #{full_path}"
        if overwrite?
          File.delete(full_path)
        else
          puts "Not overwriting #{full_path}"
          return false
        end
      end
      system "mkdir -p #{path_dir}" if ! File.directory?(path_dir)
      File.open(full_path, 'w'){|f| f.write rendered_template }
      puts "#{full_path} written"
    else
      # render to string
      return rendered_template
    end
  end
  
  def overwrite?
    if defined?(overwrite_all)      
      if overwrite_all == true
        return true
      else
        return false
      end
    end
    
    # XXX add :always and :never later - not sure how to set persistent value from here
    # response = Capistrano::CLI.ui.ask "File exists. Overwrite? ([y]es, [n]o, [a]lways, n[e]ver)" do |q|
    response = Capistrano::CLI.ui.ask "File exists. Overwrite? ([y]es, [n]o)" do |q|
      q.default = 'n'
    end
    
    case response
    when 'y'
      return true
    when 'n'
      return false
    # XXX add :always and :never later - not sure how to set persistent value from here  
    # when 'a'
    #   set :overwrite_all, true
    # when 'e'
    #   set :overwrite_all, false
    end
    
  end

  def render_template_to_file(template_name, destination_file_name, templates_dir = DEPREC_TEMPLATES_BASE)
    template_name += '.conf' if File.extname(template_name) == '' # XXX this to be removed

    file = File.join(templates_dir, template_name)
    buffer = render :template => File.read(file)

    temporary_location = "/tmp/#{template_name}"
    put buffer, temporary_location
    sudo "cp #{temporary_location} #{destination_file_name}"
    delete temporary_location
  end
  
  # Copy configs to server(s). Note there is no :pull task. No changes should 
  # be made to configs on the servers so why would you need to pull them back?
  def push_configs(app, files)
    app = app.to_s
    files.each do |file|
      # If the file path is relative we will prepend a path to this projects
      # own config directory for this service.
      if file[:path][0,1] != '/'
        full_remote_path = File.join(deploy_to, app, file[:path]) 
      else
        full_remote_path = file[:path]
      end
      full_local_path = File.join('config', app, file[:path])
      sudo "test -d #{File.dirname(full_remote_path)} || sudo mkdir -p #{File.dirname(full_remote_path)}"
      std.su_put File.read(full_local_path), full_remote_path, '/tmp/', :mode=>file['mode']
      sudo "chown #{file[:owner]} #{full_remote_path}"
    end
  end


  def append_to_file_if_missing(filename, value, options={})
    # XXX sort out single quotes in 'value' - they'l break command!
    # XXX if options[:requires_sudo] and :use_sudo then use sudo
    sudo <<-END
    sh -c '
    grep -F "#{value}" #{filename} > /dev/null 2>&1 || 
    test ! -f #{filename} ||
    echo "#{value}" >> #{filename}
    '
    END
  end

  # create new user account on target system
  def useradd(user, options={})
    options[:shell] ||= '/bin/bash' # new accounts on ubuntu 6.06.1 have been getting /bin/sh
    switches = ''
    switches += " --shell=#{options[:shell]} " if options[:shell]
    switches += ' --create-home ' unless options[:homedir] == false
    switches += " --gid #{options[:group]} " unless options[:group].nil?
    invoke_command "grep '^#{user}:' /etc/passwd || sudo /usr/sbin/useradd #{switches} #{user}", 
    :via => run_method
  end

  # create a new group on target system
  def groupadd(group, options={})
    via = options.delete(:via) || run_method
    # XXX I don't like specifying the path to groupadd - need to sort out paths before long
    invoke_command "grep '#{group}:' /etc/group || sudo /usr/sbin/groupadd #{group}", :via => via
  end

  # add group to the list of groups this user belongs to
  def add_user_to_group(user, group)
    invoke_command "groups #{user} | grep ' #{group} ' || sudo /usr/sbin/usermod -G #{group} -a #{user}",
    :via => run_method
  end

  # create directory if it doesn't already exist
  # set permissions and ownership
  # XXX move mode, path and
  def mkdir(path, options={})
    via = options.delete(:via) || :run
    # XXX need to make sudo commands wrap the whole command (sh -c ?)
    # XXX removed the extra 'sudo' from after the '||' - need something else
    invoke_command "sh -c 'test -d #{path} || mkdir -p #{path}'", :via => via
    invoke_command "chmod #{options[:mode]} #{path}", :via => via if options[:mode]
    invoke_command "chown -R #{options[:owner]} #{path}", :via => via if options[:owner]
    groupadd(options[:group], :via => via) if options[:group]
    invoke_command "chgrp -R #{options[:group]} #{path}", :via => via if options[:group]
  end
  
  def create_src_dir
    mkdir(src_dir, :mode => '0775', :group => group_src, :via => :sudo)
  end
  
  # download source package if we don't already have it
  def download_src(src_package, src_dir)
    create_src_dir
    # check if file exists and if we have an MD5 hash or bytecount to compare 
    # against if so, compare and decide if we need to download again
    if defined?(src_package[:md5sum])
      md5_clause = " && echo '#{src_package[:md5sum]}' | md5sum -c - "
    end
    apt.install( {:base => %w(wget)}, :stable )
    # XXX replace with invoke_command
    sudo <<-SUDO
    sh -c "cd #{src_dir} && test -f #{src_package[:filename]} #{md5_clause} || wget --quiet --timestamping #{src_package[:url]}"
    SUDO
  end

  # unpack src and make it writable by the group
  def unpack_src(src_package, src_dir)
    package_dir = File.join(src_dir, src_package[:dir])
    # XXX replace with invoke_command
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
    # XXX replace with invoke_command
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


  ##
  # Run a command and ask for input when input_query is seen.
  # Sends the response back to the server.
  #
  # +input_query+ is a regular expression that defaults to /^Password/.
  #
  # Can be used where +run+ would otherwise be used.
  #
  #  run_with_input 'ssh-keygen ...', /^Are you sure you want to overwrite\?/

  def run_with_input(shell_command, input_query=/^Password/)
    handle_command_with_input(:run, shell_command, input_query)
  end

  ##
  # Run a command using sudo and ask for input when a regular expression is seen.
  # Sends the response back to the server.
  #
  # See also +run_with_input+
  #
  # +input_query+ is a regular expression

  def sudo_with_input(shell_command, input_query=/^Password/)
    handle_command_with_input(:sudo, shell_command, input_query)
  end

  def invoke_with_input(shell_command, input_query=/^Password/)
    handle_command_with_input(run_method, shell_command, input_query)
  end

  ##
  # Run a command using sudo and continuously pipe the results back to the console.
  #
  # Similar to the built-in +stream+, but for privileged users.

  def sudo_stream(command)
    sudo(command) do |ch, stream, out|
      puts out if stream == :out
      if stream == :err
        puts "[err : #{ch[:host]}] #{out}"
        break
      end
    end
  end

  ##
  # Run a command using the root account.
  #
  # Some linux distros/VPS providers only give you a root login when you install.

  def run_as_root(shell_command)
    std.connect_as_root do |tempuser|
      run shell_command
    end
  end

  ##
  # Run a task using root account.
  #
  # Some linux distros/VPS providers only give you a root login when you install.
  #
  # tempuser: contains the value replaced by 'root' for the duration of this call

  def as_root()
    std.connect_as_root do |tempuser|
      yield tempuser
    end
  end
  


  private

  ##
  # Does the actual capturing of the input and streaming of the output.
  #
  # local_run_method: run or sudo
  # shell_command: The command to run
  # input_query: A regular expression matching a request for input: /^Please enter your password/

  def handle_command_with_input(local_run_method, shell_command, input_query)
    send(local_run_method, shell_command) do |channel, stream, data|
      logger.info data, channel[:host]
      if data =~ input_query
        pass = ::Capistrano::CLI.password_prompt "#{data}"
        channel.send_data "#{pass}\n"
      end
    end
  end
  
end

Capistrano.plugin :deprec2, Deprec2