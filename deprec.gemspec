require 'rubygems' 

# TODO We should use Hoe to make this easier: http://rubyforge.org/projects/seattlerb -- topfunky

SPEC = Gem::Specification.new do |spec|
  spec.name = 'deprec'
  spec.version = '1.1.0'
  spec.summary = 'deployment recipes for capistrano'
  spec.description = <<-EOF
      This project provides libraries of Capistrano tasks and extensions to 
      remove the repetative manual work associated with installing services 
      on linux servers.
  EOF
  spec.require_path = 'lib'
  # spec.autorequire = 'deprec/recipes.rb'
  # spec.platform = Gem::Platform::Ruby
  # spec.required_ruby_version = '>= 1.6.8' # I don't know
  spec.add_dependency('capistrano', '>= 1.2.0')
  spec.add_dependency('termios', '>= 0.9.4')
  candidates = Dir.glob("{bin,docs,lib,test,resources}/**/*") 
  spec.files = candidates.delete_if do |item| 
    item.include?("CVS") || item.include?("rdoc") 
  end
  spec.default_executable = "deprec"
  spec.executables = ["deprec","deprec_dotfiles"]
end
