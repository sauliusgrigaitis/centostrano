Capistrano::Configuration.instance(:must_exist).load do 
  
  # a wrapper function that only sets that value if not already set
  # this is accessible to all recipe files
  def self.default(name, *args, &block)
    unless exists?(name)
      set(name, *args, &block)
    end
  end
  
  # monkey patch Capistrano to specify a sudo prompt in order to disambiguate
  # it's password prompts on different OS's
  module Capistrano
    class Configuration
      module Actions
        module Invocation
          def sudo(command, options={}, &block)
            block ||= self.class.default_io_proc

            options = options.dup
            as = options.delete(:as)

            prompt_text = fetch(:sudo_prompt, "sudo password: ") 
            prompt = prompt_text && "-p '#{prompt_text}'"

            user = as && "-u #{as}"
            command = [fetch(:sudo, "sudo"), prompt, user, command].compact.join(" ")

            run(command, options, &sudo_behavior_callback(block))
          end
          def sudo_behavior_callback(fallback) #:nodoc:
            # in order to prevent _each host_ from prompting when the password
            # was wrong, let's track which host prompted first and only allow
            # subsequent prompts from that host.
            prompt_host = nil

            prompt_text = fetch(:sudo_prompt, "sudo password: ") 

            Proc.new do |ch, stream, out|
              if out =~ /^#{prompt_text}/
                ch.send_data "#{self[:password]}\n"
              elsif out =~ /try again/
                if prompt_host.nil? || prompt_host == ch[:server]
                  prompt_host = ch[:server]
                  logger.important out, "#{stream} :: #{ch[:server]}"
                  reset! :password
                end
              else
                fallback.call(ch, stream, out)
              end
            end
          end
        end
      end
    end
  end
    
  CHOICES_WEBSERVER = [:nginx, :apache, :none]
  CHOICES_APPSERVER = [:mongrel, :webrick, :none]
  CHOICES_DATABASE  = [:mysql, :postgres, :none]
  
  default :web_server_type, :nginx
  default :app_server_type, :mongrel
  default :db_server_type,  :mysql

  default(:web_server_type) do
    Capistrano::CLI.ui.choose do |menu| 
      CHOICES_WEBSERVER.each {|c| menu.choice(c)}
      menu.header = "select webserver type"
    end
  end

  default(:app_server_type) do
    Capistrano::CLI.ui.choose do |menu| 
      CHOICES_APPSERVER.each {|c| menu.choice(c)}
      menu.header = "select application server type"
    end
  end

  default(:db_server_type) do
    Capistrano::CLI.ui.choose do |menu| 
      CHOICES_DATABASE.each {|c| menu.choice(c)}
      menu.header = "select database server type"
    end
  end

  default(:application) do
    Capistrano::CLI.ui.ask "enter name of project(no spaces)" do |q|
      q.validate = /^[0-9a-z_]*$/
    end
  end 

  default(:domain) do
    Capistrano::CLI.ui.ask "enter domain name for project" do |q|
      q.validate = /^[0-9a-z_\.]*$/
    end
  end

  default(:repository) do
    Capistrano::CLI.ui.ask "enter repository URL for project" do |q|
      # q.validate = //
    end
  end

  # some tasks run commands requiring special user privileges on remote servers
  # these tasks will run the commands with:
  #   :invoke_command "command", :via => run_method
  # override this value if sudo is not an option
  # in that case, your use will need the correct privileges
  default :run_method, 'sudo' 

  default(:backup_dir) { Capistrano.ui.ask 'directory to store backups'}  

  # XXX rails deploy stuff
  default(:deploy_to)    { File.join( %w(/ var www apps) << application ) }
  default(:current_path) { File.join(deploy_to, "current") }
  default(:shared_path)  { File.join(deploy_to, "shared") }

  # XXX more rails deploy stuff?

  default :user, ENV['USER']         # user who is deploying
  default :group, 'deploy'           # deployment group
  default(:group_src) { group }      # group ownership for src dir
  default :src_dir, '/usr/local/src' # 3rd party src on servers lives here
  default(:web_server_aliases) { domain.match(/^www/) ? [] : ["www.#{domain}"] }    

  on :load, 'deprec:connect_canonical_tasks' 

  namespace :deprec do

    task :connect_canonical_tasks, :hosts => 'localhost' do      
      # link application specific recipes into canonical task names
      # e.g. deprec:web:restart => deprec:nginx:restart 
      metaclass = class << self; self; end
      [:web, :app, :db].each do |server|
        server_type = send("#{server}_server_type")
        if server_type != :none
          metaclass.send(:define_method, server) { namespaces[server] }
          self.namespaces[server] = deprec.send(server_type)
        end
      end
    end

    task :dump do
      require 'yaml'
      y variables
    end
     
  end
end
