Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :apache do
      
      # put apache config for site in shared/config/apache2 dir
      # link it into apps to enable, unlink to disable? 
      # http://times.usefulinc.com/2006/09/15-rails-debian-apache
      
      # XXX Check this over after a nice sleep
      #
      # def set_apache_conf
      #   if apache_default_vhost
      #     set :apache_conf, "/usr/local/apache2/conf/default.conf" unless apache_default_vhost_conf
      #   else 
      #     set :apache_conf, "/usr/local/apache2/conf/apps/#{application}.conf" unless apache_conf
      #   end
      # end
        
      set(:apache_server_name) { domain }
      set :apache_conf, nil
      set :apache_default_vhost, false
      set :apache_default_vhost_conf, nil
      set :apache_ctl, "/usr/local/apache2/bin/apachectl"
      set(:apache_server_aliases) { web_server_aliases }
      set :apache_proxy_port, 8000
      set :apache_proxy_servers, 2
      set :apache_proxy_address, "127.0.0.1"
      set :apache_ssl_enabled, false
      set :apache_ssl_ip, nil
      set :apache_ssl_forward_all, false
      set :apache_ssl_chainfile, false
      
      desc "Install apache"
      task :install do
        version = 'httpd-2.2.6'
        set :src_package, {
          :file => version + '.tar.gz',   
          :md5sum => 'd050a49bd7532ec21c6bb593b3473a5d  httpd-2.2.6.tar.gz', 
          :dir => version,  
          :url => "http://www.apache.org/dist/httpd/#{version}.tar.gz",
          :unpack => "tar zxf #{version}.tar.gz;",
          :configure => %w(
            ./configure
            --enable-mods-shared=all
            --enable-proxy 
            --enable-proxy-balancer 
            --enable-proxy-http 
            --enable-rewrite  
            --enable-cache 
            --enable-headers 
            --enable-ssl 
            --enable-deflate 
            --with-included-apr   #_so_this_recipe_doesn't_break_when_rerun
            --enable-dav          #_for_subversion_
            --enable-so           #_for_subversion_
            ;
            ).reject{|arg| arg.match '#'}.join(' '),
          :make => 'make;',
          :install => 'make install;',
          :post_install => 'install -b support/apachectl /etc/init.d/httpd;'
        }
        install_deps
        deprec2.download_src(src_package, src_dir)
        deprec2.install_from_src(src_package, src_dir)
      end
      
      desc "install dependencies for apache"
      task :install_deps do
        puts "This function should be overridden by your OS plugin!"
        apt.install( {:base => %w(build-essential zlib1g-dev zlib1g openssl libssl-dev)}, :stable )
      end

      desc "Generate configuration file(s) for apache from template(s)"
      task :config_gen, :roles => :web do
        deprec2.render('apache', 'httpd.conf.erb', 'httpd.conf')
        if apache_ssl_enabled
          deprec2.render('apache', 'httpd-ssl.conf.erb', 'httpd.conf')
        end
      end

      desc "Configure Apache. This uses the :use_sudo
      variable to determine whether to use sudo or not. By default, :use_sudo is
      set to true."
      task :config, :roles => :web do

        put 'foo', "#{shared_path}/config/httpd.conf", :mode => 0644
  
        # if apache_ssl_enabled
        #   file = File.join(File.dirname(__FILE__), "templates", "httpd-ssl.conf")
        #   ssl_buffer = render :template => File.read(file)
        #   buffer += ssl_buffer
        # end
  
        # deprec.append_to_file_if_missing('/usr/local/apache2/conf/httpd.conf', 'NameVirtualHost *:80')
      end

      desc "Start Apache"
      task :start, :roles => :web do
        send(run_method, "#{apache_ctl} start")
      end

      desc "Stop Apache"
      task :stop, :roles => :web do
        send(run_method, "#{apache_ctl} stop")
      end

      desc "Restart Apache"
      task :restart, :roles => :web do
        send(run_method, "#{apache_ctl} restart")
      end

      desc "Reload Apache"
      task :reload_apache, :roles => :web do
        send(run_method, "#{apache_ctl} reload")
      end

      desc "Set apache to start on boot"
      task :activate, :roles => :web do
        send(run_method, "update-rc.d httpd defaults")
      end
      
      desc "Set apache not to start on boot"
      task :deactivate, :roles => :web do
        send(run_method, "update-rc.d httpd remove")
      end
      
      task :backup, :roles => :web do
        # not yet implemented
      end
      
      task :restore, :roles => :web do
        # not yet implemented
      end

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
    end
  end
end