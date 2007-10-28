Capistrano::Configuration.instance(:must_exist).load do 

  task :install_rubygems do
    version = 'rubygems-0.9.4'
    set :src_package, {
      :file => version + '.tgz',
      :md5sum => 'b5680acaa019c80ea44fe87cc2e227da  rubygems-0.9.4.tgz',
      :dir => version,
      :url => "http://rubyforge.org/frs/download.php/20989/rubygems-0.9.4.tgz",
      :unpack => "tar zxf #{version}.tgz;",
      :install => '/usr/bin/ruby1.8 setup.rb;'
    }
    deprec2.download_src(src_package, src_dir)
    deprec2.install_from_src(src_package, src_dir)
    gem2.upgrade
    gem2.update_system
  end
  
end
