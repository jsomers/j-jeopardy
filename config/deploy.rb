# To deploy
# Log into server using `jeopardy` command.
#
# cd ~/public_html/jeopardy/releases
# 
# git clone git@github.com:jsomers/j-jeopardy.git 20170403075055
# 
# cd ..
# rm -rf current/
# rm current
# 
# ln -s -f releases/20170403075055/ current
# 
# current
# mkdir tmp
# 
# vim config/database.yml
# [edit the file to include the prod database password]
# 
# vim config/initializers/aws.rb
# [edit the file to include the correct key and password]
# 
# touch /home/james/public_html/jeopardy/current/tmp/restart.txt

# Must hardcode the AWS credentials because the environment doesn't have them.

# To install local gems, first find them at `~/.rvm/gems/ruby-1.8.7-p371/cache`
# then move the files to a directory, tar it
# then scp the tarball to the server
# then sudo gem install --local *.gem

ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa_black")]
default_run_options[:pty] = true
set :application, "jeopardy"

set :repository,  "git@github.com:jsomers/j-jeopardy.git"
set :scm, "git"
set :branch, "master"
set :user, "james"

set :deploy_via, :remote_cache
set :port, 30000
set :runner, "james"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/james/public_html/#{application}"

set :location, "jimbotronimo.com"
role :app, location
role :web, location
role :db,  location, :primary => true

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch /home/james/public_html/jeopardy/current/tmp/restart.txt"
  end
  
  task :start do
    # nothing
  end
end