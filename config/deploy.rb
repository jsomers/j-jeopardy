# Must hardcode the AWS credentials because the environment doesn't have them.

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