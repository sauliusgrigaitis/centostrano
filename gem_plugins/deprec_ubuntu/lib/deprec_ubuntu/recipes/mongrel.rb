Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
  namespace :mongrel do
    
  set :mongrel_servers, 2
  set :mongrel_port, 8000
  set :mongrel_address, "127.0.0.1"
  set :mongrel_environment, "production"
  set :mongrel_conf, nil
  set :mongrel_user, nil
  set :mongrel_group, nil
  set :mongrel_prefix, nil