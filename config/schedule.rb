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

MIDNIGHT = Time.now.midnight
# Apply a static offset, plus an optional configured offset, to run times of periodic jobs.
# This is to avoid them all occurring at the same time and overloading the server.
def offset(off_hours)
  off_minutes = Seek::Config.regular_job_offset || 0
  (MIDNIGHT + off_hours.hours + off_minutes.minutes).strftime("%-l:%M%P")
end

PeriodicSubscriptionEmailJob::DELAYS.each do |frequency, period|
  every period, at: offset(0) do
    runner "PeriodicSubscriptionEmailJob.new('#{frequency}').queue_job"
  end
end

every RegularMaintenanceJob::RUN_PERIOD, at: offset(1) do
  runner "RegularMaintenanceJob.perform_later"
end

every LifeMonitorStatusJob::PERIOD, at: offset(2) do
  runner "LifeMonitorStatusJob.perform_later"
end

every Seek::Config.home_feeds_cache_timeout.minutes do # Crontab will need to be regenerated if this changes...
  runner "NewsFeedRefreshJob.set(priority: 3).perform_later"
end

every 10.minutes do
  runner "ApplicationJob.queue_timed_jobs"
end

every 1.minute do
  runner 'ApplicationStatus.instance.refresh'
end

every 1.day, at: offset(3) do
  runner 'Galaxy::ToolMap.instance.refresh'
end

every 1.day, at: '12:10 am' do
  runner "Seek::BioSchema::DataDump.generate_dumps"
end

# not safe to automatically add in a non containerised environment
if Seek::Docker.using_docker?
  every 10.minutes do
    command "sh /seek/script/kill-long-running-soffice.sh"
  end
end
