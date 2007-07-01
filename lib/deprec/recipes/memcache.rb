Capistrano.configuration(:must_exist).load do
  
  set :memcache_ip, '127.0.0.1'
  set :memcache_port, 11211
  set :memcache_memory, 256
  
  # XXX needs thought/work
  task :memcached_start do
    run "memcached -d -m #{memcache_memory} -l #{memcache_ip} -p #{memcache_port}"
  end
  
  # XXX needs thought/work
  task :memcached_stop do
    run "killall memcached"
  end
  
  # XXX needs thought/work
  task :memcached_restart do
    memcached_stop
    memcached_start
  end
  
  task :install_memcached do
    version = 'memcached-1.2.2'
    set :src_package, {
      :file => version + '.tar.gz',   
      :md5sum => 'a08851f7fa7b15e92ee6320b7a79c321  memcached-1.2.2.tar.gz', 
      :dir => version,  
      :url => "http://www.danga.com/memcached/dist/#{version}.tar.gz",
      :unpack => "tar zxf #{version}.tar.gz;",
      :configure => %w{
        ./configure
        --prefix=/usr/local 
        ;
        }.reject{|arg| arg.match '#'}.join(' '),
      :make => 'make;',
      :install => 'make install;',
      :post_install => 'install -b support/apachectl /etc/init.d/httpd;'
    }
    apt.install( {:base => %w(libevent-dev)}, :stable )
    deprec.download_src(src_package, src_dir)
    deprec.install_from_src(src_package, src_dir)
  end
  
end