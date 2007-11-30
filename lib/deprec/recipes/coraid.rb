Capistrano::Configuration.instance(:must_exist).load do 
  
  namespace :deprec do
    
    namespace :coraid do
      desc "Install drivers needed to mount Coraid block devices"
      task :install do
        apt.install( {:base => %w(build-essential vblade aoetools)}, :stable )
      end
      
    end
    
    namespace :coraid_ethernet_console do
      desc "install CEC (Coraid Ethernet Console)"
      task :install do
        # XXX find URL to get this from and write up properly
        # tar zxfv cec-8.tgz
        # cd cec-8/
        # make
        # sudo make install
      end
    end
    
  end
  
end


