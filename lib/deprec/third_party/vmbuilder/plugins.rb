# plugins.rb: Load all the Capistrano Plugins in the plugins directory.

require 'rubygems'

# Load plugins from the plugins directory
Dir["#{File.dirname(__FILE__)}/plugins/*.rb"].sort.each do |plugin|
  load plugin
end
