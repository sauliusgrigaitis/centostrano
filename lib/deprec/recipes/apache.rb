Capistrano.configuration(:must_exist).load do

  task :install_apache do # deprecated
    apache_install
  end
  
  task :apache_install do
    version = 'httpd-2.2.4'
    set :src_package, {
      :file => version + '.tar.gz',   
      :md5sum => '3add41e0b924d4bb53c2dee55a38c09e  httpd-2.2.4.tar.gz', 
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
    apt.install( {:base => %w(zlib1g-dev zlib1g openssl libssl-dev)}, :stable )
    deprec.download_src(src_package, src_dir)
    deprec.install_from_src(src_package, src_dir)
    # ubuntu specific - should instead call generic name which can be picked up by different distros
    send(run_method, "update-rc.d httpd defaults")
  end
  
  task :install_php do # deprecated
    php_install
  end
  
  desc "Install PHP from source"
  task :php_install do
    version = 'php-5.2.2'
    set :src_package, {
      :file => version + '.tar.gz',
      :md5sum => '7a920d0096900b2b962b21dc5c55fe3c  php-5.2.2.tar.gz', 
      :dir => version,
      :url => "http://www.php.net/distributions/#{version}.tar.gz",
      :unpack => "tar zxf #{version}.tar.gz;",
      :configure => %w(
        ./configure 
        --prefix=/usr/local/php
        --with-apxs2=/usr/local/apache2/bin/apxs
        --disable-ipv6
        --enable-sockets
        --enable-soap
        --with-pcre-regex
        --with-mysql
        --with-zlib 
        --with-gettext
        --with-sqlite
        --enable-sqlite-utf8
        --with-openssl
        --with-mcrypt
        --with-ncurses
        --with-jpeg-dir=/usr
        --with-gd
        --with-ctype
        --enable-mbstring
        --with-curl==/usr/lib 
        ;
        ).reject{|arg| arg.match '#'}.join(' '),
      :make => 'make;',
      :install => 'make install;',
      :post_install => ""
    }
    apt.install( {:base => %w(zlib1g-dev zlib1g openssl libssl-dev 
      flex libcurl3 libcurl3-dev libmcrypt-dev libmysqlclient15-dev libncurses5-dev 
      libxml2-dev libjpeg62-dev libpng12-dev)}, :stable )
    run "export CFLAGS=-O2;"
    deprec.download_src(src_package, src_dir)
    deprec.install_from_src(src_package, src_dir)
    deprec.append_to_file_if_missing('/usr/local/apache2/conf/httpd.conf', 'AddType application/x-httpd-php .php')
  end

end