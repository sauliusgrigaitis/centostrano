Capistrano::Configuration.instance(:must_exist).load do 

  namespace :deprec do namespace :nginx do
      
  #Craig: I've kept this generic rather than calling the task setup postfix. 
  # if people want other smtp servers, it could be configurable
  desc "install and configure postfix"
  task :setup_smtp_server do
    install_postfix
    set :postfix_destination_domains, [domain] + apache_server_aliases
    deprec.render_template_to_file('postfix_main', '/etc/postfix/main.cf')
  end

  end end
end