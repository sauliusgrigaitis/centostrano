Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :example do
      
      SRC_PACKAGES[:example] = {
        :filename => 'example-1.2.3.tar.gz',   
        :md5sum => "d050a49bd72222ec21c6bb593b3473a5d  example-1.2.3.tar.gz", 
        :dir => 'example-1.2.3',  
        :url => "http://www.example.org/dist/example/example-1.2.3.tar.gz",
        :unpack => "tar zxf example-1.2.3.tar.gz;",
        :configure => %w(
          ./configure
          --enable-mods-shared=all
          --enable-proxy 
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;',
        :post_install => 'install -b support/apachectl /etc/init.d/httpd;'
      }
      
      desc "Install example"
      task :install, :roles => :web do
        install_deps
      end
      
      task :install_deps do
        apt.install( {:base => %w(build-essential zlib1g-dev)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:example] = [
        
        {:template => "example.conf.erb",
         :path => '/etc/example/example.conf',
         :mode => '0755',
         :owner => 'root:root'}
         
      ]

      PROJECT_CONFIG_FILES[:example] = [
        
        {:template => "example.conf.erb",
         :path => 'conf/example.conf',
         :mode => '0755',
         :owner => 'root:root'}
      ]
      
      
      desc "Generate configuration file(s) for XXX from template(s)"
      task :config_gen do
        config_gen_system
        config_gen_project
      end

      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:example].each do |file|
          deprec2.render_template(:example, file)
        end
      end

      task :config_gen_project do
        PROJECT_CONFIG_FILES[:example].each do |file|
          deprec2.render_template(:example, file)
        end
      end
      
      desc 'Deploy configuration files(s) for XXX' 
      task :config, :roles => :web do
        config_system
        config_project
      end

      task :config_system, :roles => :web do
        deprec2.push_configs(:example, SYSTEM_CONFIG_FILES[:example])
      end

      task :config_project, :roles => :web do
        deprec2.push_configs(:example, PROJECT_CONFIG_FILES[:example])
      end
      
      
      task :start, :roles => :web do
      end
      
      task :stop, :roles => :web do
      end
      
      task :restart, :roles => :web do
      end
      
      task :activate, :roles => :web do
      end  
      
      task :deactivate, :roles => :web do
      end
      
      task :backup, :roles => :web do
      end
      
      task :restore, :roles => :web do
      end
      
    end
  end
end