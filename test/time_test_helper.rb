# pretend_now_is method can be used to make Time.now calls by the block return a specified time.

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

class Time
  class <<self
    attr_writer :testing_offset
    attr_accessor :fake_now
    alias_method :real_now, :now
    def now
      fake_now || real_now - testing_offset
    end
    alias_method :new, :now

    def testing_offset
      @testing_offset || 0
    end

  end
end


class Test::Unit::TestCase

  def pretend_now_is(time)
    begin
      Time.testing_offset = Time.now - time
      yield
    ensure
      Time.testing_offset = 0
    end
  end

  def force_now_is(time)
    begin
      Time.fake_now = time
      yield
    ensure
      Time.fake_now = nil
    end
  end
end