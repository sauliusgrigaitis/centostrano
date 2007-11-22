Capistrano::Configuration.instance(:must_exist).load do 
  
  APACHE_DEPS = %w(build-essential zlib1g-dev zlib1g openssl libssl-dev)
  
  namespace :deprec do
    namespace :apache do
      
      desc "install dependencies for apache"
      task :install_deps do
        apt.install( {:base => APACHE_DEPS}, :stable )
      end

    end
  end
  

  
end