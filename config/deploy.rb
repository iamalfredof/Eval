set :application, 'udoczp2h'
set :repo_url, 'git@github.com:Patrax/udocz_p2h.git'

set :passenger_restart_with_touch, true

set :deploy_to, '/home/deploy/udoczp2h'

set :linked_files, %w{config/database.yml config/secrets.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :use_sudo, false
# set :rails_env, "production"
# set :deploy_via, :remote_cache
# set :ssh_options, { user: 'ubuntu', :forward_agent => true, :port => 22, keys: ["#{ENV['HOME']}/.ssh/id_rsa"]}

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
end