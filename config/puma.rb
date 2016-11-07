require 'system'
# Change to match your CPU core count
workers System::CPU.count

# Min and Max threads per worker
threads 1, 6

# Default to development
rails_env = ENV['RAILS_ENV'] || "development"
environment rails_env

bind 'tcp://0.0.0.0:2000'
# bind 'unix:///var/run/puma.sock'
# bind 'unix:///var/run/puma.sock?umask=0111'
# bind 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'
