path = "/Users/mbailey/work/deprec_ubuntu/lib/"
# path = ''
require 'capistrano'
require "#{path}deprec_ubuntu/recipes/apache"
require "#{path}deprec_ubuntu/recipes/php"

Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ubuntu do
      
      desc "ubuntu default task"
      task :default do
        puts 'deprec:ubuntu'
      end
      
    end
  end
end