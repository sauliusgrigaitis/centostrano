Capistrano::Configuration.instance(:must_exist).load do 
  # before 'deprec:php:install', :blah
  
  namespace :deprec do
    namespace :php do
      before 'deprec:php:install', 'deprec:php:blah'
      desc 'deprec:php:blah'
      task :blah, :roles => :web do
        puts "before deprec:php:install (deprec_ubuntu)"                       
      end
    end
  end
end