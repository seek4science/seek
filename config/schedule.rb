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

# All periodic *application* jobs now live in config/recurring.yml, run by Solid Queue's own
# scheduler (see RecurringTest). Only genuine OS/shell maintenance that doesn't map onto an
# ActiveJob or Ruby call remains here on whenever/cron.

# Reap LibreOffice (soffice.bin) processes left running longer than 30 minutes by document
# conversion. This is process reaping at the container level, not application logic, so it stays on
# cron rather than moving to a Solid Queue recurring job. Only added in a containerised environment.
if Seek::Docker.using_docker?
  every 10.minutes do
    command "sh /seek/script/kill-long-running-soffice.sh"
  end
end
