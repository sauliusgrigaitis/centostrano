unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/multistage requires Capistrano 2"
end
load "#{File.dirname(__FILE__)}/vmbuilder_plugins/all.rb"
load "#{File.dirname(__FILE__)}/recipes/deprec.rb"
load "#{File.dirname(__FILE__)}/capistrano_extensions/deprec2_extensions.rb"
load "#{File.dirname(__FILE__)}/third_party/vmbuilder/plugins/std.rb"

Dir["#{File.dirname(__FILE__)}/recipes/*.rb"].each { |ext| load ext }


# path = "/Users/mbailey/work/deprec/lib/"
# path = ''
# require "#{path}deprec/recipes/users"
# require "#{path}deprec/recipes/deprecated"
# require "#{path}deprec/recipes/canonical"
# require "#{path}deprec/recipes/ssh"
# require "#{path}deprec/recipes/apache"
# require "#{path}deprec/recipes/nginx"
# require "#{path}deprec/recipes/mongrel"
# require "#{path}deprec/recipes/mysql"
# require "#{path}deprec/recipes/php"
# require "#{path}deprec/recipes/subversion.rb"
# require "#{path}deprec/recipes/trac.rb"
# require "#{path}deprec/third_party/vmbuilder/plugins"
