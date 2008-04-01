# Copyright 2006-2008 by Mike Bailey. All rights reserved.
require 'fileutils'
require 'uri'

# http://svnbook.red-bean.com/en/1.4/svn-book.html#svn.serverconfig.choosing.apache

Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do namespace :git do
  
  set :scm_group, 'scm'

  # Extract svn attributes from :repository URL
  # 
  # Two examples of :repository entries are:
  #
  #   set :repository, 'svn+ssh://scm.deprecated.org/var/svn/deprec/trunk'
  #   set :repository, 'file:///tmp/svn/deprec/trunk'
  #
  # This has only been tested with svn+ssh but file: should work.
  #
  desc "Install Subversion"
  task :install, :roles => :scm do
    install_deps
    # XXX should really check if apache has already been installed
    # XXX can do that when we move to rake
    # deprec2.download_src(src_package, src_dir)
    # deprec2.install_from_src(src_package, src_dir)
  end
  
  desc "install dependencies for Subversion"
  task :install_deps do
    enable_atrpms_dag_repositories
    apt.install( {:base => %w(git)}, :stable , {:repositories => [:atrpms, :dag]})
    # XXX deprec1 - was building from source to get subversion-1.4.5 onto dapper. Compiled swig bindings for trac
    # apt.install( {:base => %w(build-essential wget libneon25 libneon25-dev swig python-dev libexpat1-dev)}, :stable )
  end
 
  desc "enable atrmps and dag repositories"
  task :enable_atrpms_dag_repositories do
    repository_configs = [
      {
        :template => 'repository.erb',
        :path => '/etc/yum.repos.d/atrpms.repo',
        :mode => 0644,
        :owner => 'root:root',
        :remote => true,
        :repository => { 
          :code => "atrpms",
          :name => "ATrpms for Enterprise Linux $releasever - $basearch",
          :baseurl => "http://dl.atrpms.net/el$releasever-$basearch/atrpms/stable",
          :enabled => "0",
          :gpgcheck => "1",
          :gpgkey => "http://ATrpms.net/RPM-GPG-KEY.atrpms"
        }
      },
      {
        :template => 'repository.erb',
        :path => '/etc/yum.repos.d/dag.repo',
        :mode => 0644,
        :owner => 'root:root',
        :remote => true,
        :repository => { 
          :code => "dag",
          :name => "Dag",
          :baseurl => "http://dag.freshrpms.net/redhat/el4/en/$basearch/dag\nhttp://ftp.heanet.ie/pub/freshrpms/pub/dag/redhat/el4/en/i386/dag/",
          :enabled => "0",
          :gpgcheck => "1",
          :gpgkey => "http://dag.wieers.com/packages/RPM-GPG-KEY.dag.txt"
        }
      } 
    ]
    repository_configs.each { |rc| deprec2.render_template(:centos, rc) }
  end
  # XXX TODO
  # desc "backup repository" 
  # task :svn_backup_respository, :roles => :scm do
  #   puts "read http://svnbook.red-bean.com/nightly/en/svn-book.html#svn.reposadmin.maint.backup"
  # end
  end end
end

# svnserve setup
# I've previously used ssh exclusively I've decided svnserve is a reasonable choice for collaboration on open source projects.
# It's easier to setup than apache/ssl webdav access.
#
# sudo useradd svn
# sudo mkdir -p /var/svn/deprec_svnserve_root
# sudo ln -sf /var/www/apps/deprec/repos /var/svn/deprec_svnserve_root/deprec
# sudo chown -R svn /var/svn/deprec_svnserve_root/deprec

#
# XXX put password file into svn and command to push it
# 
# # run svnserve
# sudo -u svn svnserve --daemon --root /var/svn/deprec_svnserve_root
# 
# # check it out now
# svn co svn://scm.deprecated.org/deprec/trunk deprec
