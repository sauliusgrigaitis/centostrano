require 'rubygems' 

SPEC = Gem::Specification.new do |spec|
  spec.name = 'centostrano'
  spec.author = 'Saulius Grigaitis'
  spec.email = 'saulius.grigaitis@gmail.com'
  spec.homepage = 'http://www.rubyonrails.lt'
  spec.rubyforge_project = 'centostrano'
  spec.version = '1.99.15'
  spec.summary = 'CentOS deployment recipes for capistrano'
  spec.description = <<-EOF
      This project is port of deprec2 for CentOS. Centostrano provides libraries 
      of Capistrano tasks and extensions to remove the repetative manual work 
      associated with installing services on linux servers.
  EOF
  spec.require_path = 'lib'
  spec.add_dependency('capistrano', '> 2.0.0')
  candidates = Dir.glob("{bin,docs,lib,test,resources}/**/*") 
  candidates.concat(%w(COPYING LICENSE README.txt THANKS))
  spec.files = candidates.delete_if do |item| 
    item.include?("CVS") || item.include?("rdoc") 
  end
  spec.default_executable = "centify"
  spec.executables = ["centify"]
end
