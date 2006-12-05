Capistrano.configuration(:must_exist).load do
  
  set :apache_server_name, nil
  set :apache_conf, nil
  set :apache_default_vhost, false
  set :apache_default_vhost_conf, nil
  set :apache_ctl, "/etc/init.d/httpd"
  set :apache_server_aliases, []
  set :apache_proxy_port, 8000
  set :apache_proxy_servers, 2
  set :apache_proxy_address, "127.0.0.1"
  set :apache_ssl_enabled, false
  set :apache_ssl_ip, nil
  set :apache_ssl_forward_all, false
  
  task :setup_apache, :roles => :web do
    set :apache_path, '/usr/local/apache2'
    apps_dir = "#{apache_path}/conf/apps"
    sudo "test -d #{apps_dir} || sudo mkdir -p #{apps_dir}"
    sudo "chgrp #{group} #{apps_dir}"
    sudo "chmod g+w #{apps_dir}"
    inc_cmd = 'Include conf/apps/'
    # XXX quick hack to permit me to add to file
    sudo "chmod 766 #{apache_path}/conf/httpd.conf"
    sudo "grep '#{inc_cmd}' #{apache_path}/conf/httpd.conf || sudo echo '#{inc_cmd}' >> #{apache_path}/conf/httpd.conf"
    sudo "chmod 755 #{apache_path}/conf/httpd.conf"
    index = '/usr/local/apache2/htdocs/index.html'
    sudo "test ! -f #{index} || sudo mv #{index} #{index}.bak"
  end
  
  desc "Configure Apache. This uses the :use_sudo
  variable to determine whether to use sudo or not. By default, :use_sudo is
  set to true."
  task :configure_apache, :roles => :web do
    set_apache_conf
        
    server_aliases = []
    server_aliases << "www.#{apache_server_name}"
    server_aliases.concat apache_server_aliases
    set :apache_server_aliases_array, server_aliases
    
    file = File.join(File.dirname(__FILE__), "templates", "httpd.conf")
    buffer = render :template => File.read(file)
    
    if apache_ssl_enabled
      file = File.join(File.dirname(__FILE__), "templates", "httpd-ssl.conf")
      ssl_buffer = render :template => File.read(file)
      buffer += ssl_buffer
    end
    
    put buffer, "#{shared_path}/httpd.conf"
    send(run_method, "cp #{shared_path}/httpd.conf #{apache_conf}")
    delete "#{shared_path}/httpd.conf"
  end
  
  desc "Start Apache "
  task :start_apache, :roles => :web do
    send(run_method, "#{apache_ctl} start")
  end
  
  desc "Restart Apache "
  task :restart_apache, :roles => :web do
    send(run_method, "#{apache_ctl} restart")
  end
  
  desc "Stop Apache "
  task :stop_apache, :roles => :web do
    send(run_method, "#{apache_ctl} stop")
  end
  
  desc "Reload Apache "
  task :reload_apache, :roles => :web do
    send(run_method, "#{apache_ctl} reload")
  end
  
  def set_apache_conf
    if apache_default_vhost
      set :apache_conf, "/usr/local/apache2/conf/default.conf" unless apache_default_vhost_conf
    else 
      set :apache_conf, "/usr/local/apache2/conf/apps/#{application}.conf" unless apache_conf
    end
  end
  
end