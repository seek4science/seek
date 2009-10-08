# pretend_now_is method can be used to make Time.now calls by the block return a specified time.

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

class Time
  class <<self
    attr_accessor :testing_offset
    alias_method :real_now, :now
    def now
      real_now - testing_offset
    end
    alias_method :new, :now
  end
end
Time.testing_offset = 0

class Test::Unit::TestCase

  def pretend_now_is(time)
    begin
      Time.testing_offset = Time.now - time
      yield
    ensure
      Time.testing_offset = 0
    end
  end
end