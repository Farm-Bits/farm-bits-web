# config valid for current version and patch releases of Capistrano
lock "~> 3.20.0"

set :application, "farm_bits"
set :repo_url, "git@github.com:Farm-Bits/web_application.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/database.yml", "config/credentials/production.key", "config/application.yml", ".env"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# jemalloc - reduces Ruby memory fragmentation by 30-50%
# Applies to both Puma and Sidekiq systemd units
jemalloc_env_vars = [
  'LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2',
  'MALLOC_CONF=narenas:2,background_thread:true,dirty_decay_ms:1000,muzzy_decay_ms:0'
]

set :puma_service_unit_env_vars,    jemalloc_env_vars
set :sidekiq_service_unit_env_vars, jemalloc_env_vars
