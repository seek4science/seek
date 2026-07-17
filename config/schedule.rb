# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
#

# Set environment variables
ENV.each_key do |key|
  env key.to_sym, ENV[key]
end

require File.expand_path(File.dirname(__FILE__) + "/../config/environment") unless defined? SEEK

set :output, "#{path}/log/schedule.log"

# Everything that's an ActiveJob enqueue or a plain Ruby method call lives in
# config/recurring.yml, run by Solid Queue's own scheduler. Only rake tasks and shell commands
# remain here, since neither maps onto recurring.yml's `class:`/`command:` mechanisms.

# Generate a new sitemap...
every 1.day, at: '12:45 am' do
  rake "-s sitemap:refresh"
end

# not safe to automatically add in a non containerised environment
if Seek::Docker.using_docker?
  every 10.minutes do
    command "sh /seek/script/kill-long-running-soffice.sh"
  end
end

# trim sessions
every 1.day, at: '1:15 am' do
  rake 'db:sessions:batch_trim'
end
