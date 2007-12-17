Capistrano::Configuration.instance(:must_exist).load do 

  namespace :deprec do
    namespace :ruby do
      
      SRC_PACKAGES[:ruby] = {
        :filename => 'ruby-1.8.6-p110.tar.gz',   
        :md5sum => "5d9f903eae163cda2374ef8fdba5c0a5  ruby-1.8.6-p110.tar.gz", 
        :dir => 'ruby-1.8.6-p110',  
        :url => "ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p110.tar.gz",
        :unpack => "tar zxf ruby-1.8.6-p110.tar.gz;",
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
        deprec2.install_from_src(SRC_PACKAGES[:ruby], src_dir)
      end
      
      task :install_deps do
        # pass
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
        gem2.upgrade
        gem2.update_system
      end
      
      task :install_deps do
        # we need ruby but don't currently have a mechanism to check 
        # whether we've installed it.
      end
      
    end 
  end
  
end
