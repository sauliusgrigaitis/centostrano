
## 
# Caches an svn copy of your app locally to avoid doing a full checkout of 
# your app each time. Overwrites the built-in +update_code+ task.
#
# Written/pulled together by Dreamer3 (Josh Goebel) based on work by Chris McGrath (octopod).
# Minor tweaks by Geoffrey Grosenbach (topfunky).
#
# Usage:
#
#   # In deploy.rb
#   require 'deprec/recipes/cache_svn'
#
#   set :repository, "svn://your.repository/path/here"
#   set :repository_cache, "#{shared_path}/svn_trunk/"
#
# After running the default +setup+ task, run +setup_repository_cache+ to
# do the first checkout of your app. 
#
#   cap setup_repository_cache
#
# After that, the normal +deploy+ will update the cached copy, rsync 
# it to the releases directory, and symlink it to +current+, as usual.

##
# Expand the subversion class to support cached repositories
class Capistrano::SCM::Subversion

  def setup_repository_cache(actor)
    params =  ""
    params << "--username #{configuration.svn_username}" if configuration.svn_username
    command = "#{svn} co -q -v #{params} #{configuration.repository} #{configuration.repository_cache} &&"
    configuration.logger.debug "Caching SVN repository on remote servers..."
    run_checkout(actor, command, &svn_stream_handler(actor)) 
  end

  def update_repository_cache(actor)
    command = "#{svn} up -q #{configuration.repository_cache} &&"
    run_update(actor, command, &svn_stream_handler(actor)) 
  end

end

Capistrano.configuration(:must_exist).load do

  desc <<-DESC
  Setup the cached repository on the server for the first time and
  checkout the latest version there.
  DESC
  task :setup_cached_repository, :roles => [:app, :db, :web] do
    set :revision, "Initial setup checkout" # avoids capistrano trying to find out for us
    run "mkdir -p #{repository_cache}"
    source.setup_repository_cache(self)
  end

  desc <<-DESC
  Update the cached repository and then your app (from the cache) via SVN.
  DESC
  task :update_code, :roles => [:app, :db, :web] do
    source.update_repository_cache(self)

    on_rollback { delete release_path, :recursive => true }

    run %(rsync -ax --exclude=".svn" #{repository_cache} #{release_path}/)

    run <<-CMD
      rm -rf #{release_path}/log #{release_path}/public/system &&
      ln -nfs #{shared_path}/log #{release_path}/log &&
      ln -nfs #{shared_path}/system #{release_path}/public/system
    CMD

  end

end
