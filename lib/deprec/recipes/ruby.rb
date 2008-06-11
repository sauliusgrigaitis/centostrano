# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  namespace :centos do
    namespace :ruby do
            
      SRC_PACKAGES[:ruby] = {
        :filename => 'ruby-1.8.6-p114.tar.gz',   
        :md5sum => "500a9f11613d6c8ab6dcf12bec1b3ed3  ruby-1.8.6-p114.tar.gz", 
        :dir => 'ruby-1.8.6-p114',  
        :url => "ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p114.tar.gz",
        :unpack => "tar zxf ruby-1.8.6-p114.tar.gz;",
        :configure => %w(
          ./configure
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;'
      }
  
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ruby], src_dir)
        yum.install_from_src(SRC_PACKAGES[:ruby], src_dir)
      end
      
      task :install_deps do
        apt.install( {:base => %w(pcre* gcc make openssl openssl-devel)}, :stable )
      end

    end
  end
  
  
  namespace :centos do
    namespace :rubygems do
  
      SRC_PACKAGES[:rubygems] = {
        :filename => 'rubygems-1.0.1.tgz',   
        :md5sum => "0d5851084955c327ee1dc9cbd631aa5f  rubygems-1.0.1.tgz", 
        :dir => 'rubygems-1.0.1',  
        :url => "http://rubyforge.org/frs/download.php/29548/rubygems-1.0.1.tgz",
        :unpack => "tar zxf rubygems-1.0.1.tgz;",
        :install => 'ruby setup.rb;'
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
