Capistrano::Configuration.instance(:must_exist).load do 
  
  # Central place to store the locations we get source packages from.
  # You can change these to your own webserver if you like. 
  SRC_PACKAGES = {}
  
  SRC_PACKAGES[:apache] = {
    :filename => 'httpd-2.2.6.tar.gz',   
    :md5sum => "d050a49bd7532ec21c6bb593b3473a5d  httpd-2.2.6.tar.gz", 
    :dir => 'httpd-2.2.6',  
    :url => "http://www.apache.org/dist/httpd/httpd-2.2.6.tar.gz",
    :unpack => "tar zxf httpd-2.2.6.tar.gz;",
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
end