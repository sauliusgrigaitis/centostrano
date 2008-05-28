unless Capistrano::Configuration.respond_to?(:instance)
  abort "Centostrano requires Capistrano 2"
end

require "#{File.dirname(__FILE__)}/deprec/capistrano_extensions"
require "#{File.dirname(__FILE__)}/deprec/centostrano"
require "#{File.dirname(__FILE__)}/vmbuilder_plugins/all"
require "#{File.dirname(__FILE__)}/deprec/recipes"

