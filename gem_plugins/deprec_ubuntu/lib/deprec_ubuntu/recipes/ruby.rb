task :install_rubygems do
  # XXX should check for presence of ruby first!
  version = 'rubygems-0.9.2'
  set :src_package, {
    :file => version + '.tgz',
    :md5sum => 'cc525053dd465ab6e33af382166fa808  rubygems-0.9.2.tgz',
    :dir => version,
    :url => "http://rubyforge.org/frs/download.php/17190/#{version}.tgz",
    :unpack => "tar zxf #{version}.tgz;",
    :install => '/usr/bin/ruby1.8 setup.rb;'
  }
  deprec.download_src(src_package, src_dir)
  deprec.install_from_src(src_package, src_dir)
  gem.upgrade
  gem.update_system
end