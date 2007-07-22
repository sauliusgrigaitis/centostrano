# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/deprec.rb'

Hoe.new('deprec', Deprec::VERSION) do |p|
  p.rubyforge_name = 'deprec'
  p.author = 'Mike Bailey'
  p.email = 'mike@bailey.net.au'
  p.summary = 'deployment recipes for capistrano'
  p.description = <<-EOF
        This project provides libraries of Capistrano tasks and extensions to 
        remove the repetitive manual work associated with installing services 
        on linux servers.
  EOF
  p.extra_deps << ['capistrano']
  p.extra_deps << ['gem_plugin', '>= 0.2.2']
  
  # p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.remote_rdoc_dir = '' # Release to root
end

# vim: syntax=Ruby
