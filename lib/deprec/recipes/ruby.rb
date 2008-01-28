Capistrano::Configuration.instance(:must_exist).load do 

  namespace :deprec do
    namespace :ruby do
      
      ext_zlib = 'cd ext/zlib; ruby extconf.rb; make;  make test; make install;'
      ext_openssl = 'cd ext/openssl; ruby extconf.rb; make;  make test; make install;'
      
      SRC_PACKAGES[:ruby] = {
        :filename => 'ruby-1.8.6-p110.tar.gz',   
        :md5sum => "5d9f903eae163cda2374ef8fdba5c0a5  ruby-1.8.6-p110.tar.gz", 
        :dir => 'ruby-1.8.6-p110',  
        :url => "ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p110.tar.gz",
        :unpack => "tar zxf ruby-1.8.6-p110.tar.gz;",
        :configure => %w(
          ./configure
          --with-readline-dir=/usr/local
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;',
        :post_install => "#{ext_zlib} #{ext_openssl}"
      }
  
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ruby], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ruby], src_dir)
      end
      
      task :install_deps do
        apt.install( {:base => %w(zlib1g-dev libssl-dev)}, :stable )
      end

    end
  end
  
  
  namespace :deprec do
    namespace :rubygems do
  
      SRC_PACKAGES[:rubygems] = {
        :filename => 'rubygems-0.9.5.tgz',   
        :md5sum => "91f7036a724e34cc66dd8d09348733d9  rubygems-0.9.5.tgz", 
        :dir => 'rubygems-0.9.5',  
        :url => "http://rubyforge.org/frs/download.php/28174/rubygems-0.9.5.tgz",
        :unpack => "tar zxf rubygems-0.9.5.tgz;",
        :install => 'ruby setup.rb;'
      }
      
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:rubygems], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:rubygems], src_dir)
        # gem2.upgrade #  you may not want to upgrade your gems right now
        # If we want to selfupdate then we need to 
        # create symlink as latest gems version is broken
        # gem2.update_system
        # sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
      end
      
      # install dependencies for rubygems
      task :install_deps do
      end
      
    end 
  end
  
end
