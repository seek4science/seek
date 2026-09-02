require 'test_helper'
require 'seek/redis_config'

class RedisConfigTest < ActiveSupport::TestCase
  def with_env(vars)
    original = vars.transform_values { |_| :__unset__ }
    vars.each_key { |k| original[k] = ENV.key?(k) ? ENV[k] : :__unset__ }
    vars.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    original.each { |k, v| v == :__unset__ ? ENV.delete(k) : ENV[k] = v }
  end

  test 'defaults to localhost with no host or password' do
    with_env('REDIS_HOST' => nil, 'REDIS_PASSWORD' => nil) do
      assert_equal 'redis://localhost:6379/0', Seek::RedisConfig.url
    end
  end

  test 'uses REDIS_HOST without auth when no password is set' do
    with_env('REDIS_HOST' => 'redis_store', 'REDIS_PASSWORD' => nil) do
      assert_equal 'redis://redis_store:6379/0', Seek::RedisConfig.url
    end
  end

  test 'includes the password when set' do
    with_env('REDIS_HOST' => 'redis_store', 'REDIS_PASSWORD' => 'seek_redis_password') do
      assert_equal 'redis://:seek_redis_password@redis_store:6379/0', Seek::RedisConfig.url
    end
  end

  test 'URL-encodes special characters in the password' do
    with_env('REDIS_HOST' => 'redis_store', 'REDIS_PASSWORD' => 'p@ss:w/rd') do
      assert_equal 'redis://:p%40ss%3Aw%2Frd@redis_store:6379/0', Seek::RedisConfig.url
    end
  end

  test 'an empty password string is treated as no password' do
    with_env('REDIS_HOST' => 'redis_store', 'REDIS_PASSWORD' => '') do
      assert_equal 'redis://redis_store:6379/0', Seek::RedisConfig.url
    end
  end
end
