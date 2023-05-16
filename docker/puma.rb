require 'concurrent-ruby'
# Match your CPU core count unless specified by PUMA_WORKERS_NUM
workers ENV.fetch('PUMA_WORKERS_NUM') { Concurrent.processor_count }

worker_timeout 120

# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
preload_app!

# Min and Max threads per worker
threads 1, 1

# Default to development
rails_env = ENV.fetch('RAILS_ENV') { "development" }
environment rails_env

stdout_redirect 'log/puma.out', 'log/puma.err'


bind 'tcp://0.0.0.0:2000'
# bind 'unix:///var/run/puma.sock'
# bind 'unix:///var/run/puma.sock?umask=0111'
# bind 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'
