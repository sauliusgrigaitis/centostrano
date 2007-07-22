task :install_rubygems do
  version = 'rubygems-0.9.2'
  set :src_package, {
    :file => version + '.tgz',
    :md5sum => 'cc525053dd465ab6e33af382166fa808  rubygems-0.9.2.tgz',
    :dir => version,
    :url => "http://rubyforge.org/frs/download.php/17190/#{version}.tgz",
    :unpack => "tar zxf #{version}.tgz;",
    :install => '/usr/bin/ruby1.8 setup.rb;'
  }
  deprec2.download_src(src_package, src_dir)
  deprec2.install_from_src(src_package, src_dir)
  gem2.upgrade
  gem2.update_system
end
