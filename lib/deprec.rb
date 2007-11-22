class Deprec
  VERSION = '1.10.0'
end

unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end

require "#{File.dirname(__FILE__)}/deprec/capistrano_extensions/deprec2_extensions"
# require "#{File.dirname(__FILE__)}/third_party/vmbuilder/plugins/std"
require "#{File.dirname(__FILE__)}/deprec/vmbuilder_plugins/all"
require "#{File.dirname(__FILE__)}/deprec/recipes"

