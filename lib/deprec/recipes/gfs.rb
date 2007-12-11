Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :gfs do
      
      # ref: http://sources.redhat.com/cluster/doc/usage.txt
      
      SYSTEM_CONFIG_FILES[:gfs] = [
                
        {:template => "lvm.conf.erb",
         :path => '/etc/lvm/lvm.conf',
         :mode => '0644',
         :owner => 'root:root'},
        
        {:template => "cluster.conf.erb",
         :path => '/etc/cluster/cluster.conf',
         :mode => '0644',
         :owner => 'root:root'}
      ]
      
      desc "Install GFS utilities"
      task :task_name, :roles => roles_this_task_affects do
        # sudo apt-get install gfs2-tools clvm cman # (plus redhat-cluster-suite?)
      end
      
    end
  end
end