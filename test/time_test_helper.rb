# pretend_now_is method can be used to make Time.now calls by the block return a specified time.

ENV['RAILS_ENV'] = 'test'
require File.expand_path(File.dirname(__FILE__) + '/../config/environment')

class Time
  class <<self
    attr_accessor :pretend_time
    alias_method :real_now, :now
    def now
      pretend_time.nil? ? real_now : pretend_time
    end
  end
end

# to get local/current time with specified time zone, e.g. with_time_zone("UTC")) {Time.now} returns the current time of time zone 'UTC'
def with_time_zone(tz_name)
  prev_tz = ENV['TZ']
  ENV['TZ'] = tz_name
  yield
ensure
  ENV['TZ'] = prev_tz
end

def pretend_now_is(time)
  Time.pretend_time = time
  yield
ensure
  Time.pretend_time = nil
end
