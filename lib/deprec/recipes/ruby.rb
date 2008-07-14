# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  namespace :centos do
    namespace :ruby do
            
      SRC_PACKAGES[:ruby] = {
        :filename => 'ruby-1.8.6-p111.tar.gz',   
        :md5sum => "c36e011733a3a3be6f43ba27b7cd7485 ruby-1.8.6-p111.tar.gz", 
        :dir => 'ruby-1.8.6-p111',  
        :url => "ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p111.tar.gz",
        :unpack => "tar zxf ruby-1.8.6-p111.tar.gz; cd ruby-1.8.6-p111; wget -q -O - wget http://blog.phusion.nl/assets/r8ee-security-patch-20080623-2.txt | patch -p1",
        :configure => %w(
          ./configure
          --with-install-readline
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;',
        :version => 'c1.8.6',
        :release => '111eephusion'
      }
  
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ruby], src_dir)
        yum.install_from_src(SRC_PACKAGES[:ruby], src_dir)
      end
      
      task :install_deps do
        apt.install( {:base => %w(pcre* gcc make openssl openssl-devel readline-devel)}, :stable )
      end

    end
  end
  
  
  namespace :centos do
    namespace :rubygems do
  
      SRC_PACKAGES[:rubygems] = {
        :filename => 'rubygems-1.2.0.tgz',   
        :md5sum => "b77a4234360735174d1692e6fc598402 rubygems-1.2.0.tgz", 
        :dir => 'rubygems-1.2.0',  
        :url => "http://rubyforge.org/frs/download.php/38646/rubygems-1.2.0.tgz",
        :unpack => "tar zxf rubygems-1.2.0.tgz;",
        :install => 'ruby setup.rb;',
        :version => 'c1.2.0',
        :release => '1'
      }
      
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:rubygems], src_dir)
        yum.install_from_src(SRC_PACKAGES[:rubygems], src_dir)
        # gem2.upgrade #  you may not want to upgrade your gems right now
        # If we want to selfupdate then we need to 
        # create symlink as latest gems version is broken
        # gem2.update_system
        # sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
      end
      
      # install dependencies for rubygems
      task :install_deps do
        apt.install( {:base => %w(pcre* gcc make openssl openssl-devel)}, :stable )
      end
      
    end 
  end
  
end
