require 'test_helper'
require 'minitest/mock'
require 'mock_redis'

# Rack::Attack keeps its throttle counters in a cache store. That store used to be an in-process
# MemoryStore, so each app instance counted independently and the effective limit was multiplied by
# the number of instances (see config/initializers/rack_attack.rb). These tests drive the real
# Rack::Attack middleware to check that a Redis-backed store shares counts across instances, and
# that the initializer wires the store up the way each environment needs.
class RackAttackTest < ActiveSupport::TestCase
  LIMIT = 3

  setup do
    @original_store = Rack::Attack.cache.store
    @mock_redis = MockRedis.new
    Rack::Attack.clear_configuration
  end

  teardown do
    Rack::Attack.clear_configuration
    Rack::Attack.cache.store = @original_store
    # Reload the initializer so the app-wide configuration survives this test.
    load Rails.root.join('config/initializers/rack_attack.rb')
  end

  # A store of the kind a single app instance would hold - separate objects, one shared Redis.
  def instance_store
    ActiveSupport::Cache::RedisCacheStore.new(redis: @mock_redis, namespace: 'rack-attack')
  end

  def app
    Rack::Builder.new do
      use Rack::Attack
      run ->(_env) { [200, { 'content-type' => 'text/plain' }, ['ok']] }
    end.to_app
  end

  def throttle_by_ip
    Rack::Attack.throttle('test/ip', limit: LIMIT, period: 1.minute, &:ip)
  end

  def get(path = '/', ip: '1.2.3.4')
    app.call(Rack::MockRequest.env_for(path, 'REMOTE_ADDR' => ip)).first
  end

  test 'requests are throttled once the limit is exceeded' do
    Rack::Attack.cache.store = instance_store
    throttle_by_ip

    LIMIT.times { assert_equal 200, get }
    assert_equal 429, get
  end

  test 'throttle counts are shared across app instances using the same redis' do
    throttle_by_ip

    # Each request is served by a different instance, i.e. a different store object, but they all
    # talk to the same Redis - so between them they exhaust the limit.
    LIMIT.times do
      Rack::Attack.cache.store = instance_store
      assert_equal 200, get
    end

    Rack::Attack.cache.store = instance_store
    assert_equal 429, get
  end

  test 'separate memory stores do not share counts, which is the behaviour being replaced' do
    throttle_by_ip

    (LIMIT + 1).times do
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      assert_equal 200, get
    end
  end

  test 'throttling is keyed on the discriminator, so other clients are unaffected' do
    Rack::Attack.cache.store = instance_store
    throttle_by_ip

    (LIMIT + 1).times { get(ip: '1.2.3.4') }
    assert_equal 429, get(ip: '1.2.3.4')
    assert_equal 200, get(ip: '5.6.7.8')
  end

  test 'requests are allowed through when redis is unreachable' do
    # Port 1 has nothing listening, so every call to the store raises a connection error.
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
      url: 'redis://localhost:1/0',
      connect_timeout: 0.1,
      error_handler: ->(method:, returning:, exception:) {}
    )
    throttle_by_ip

    (LIMIT + 1).times { assert_equal 200, get }
  end

  test 'the test environment uses an in-memory store so no redis server is needed' do
    load Rails.root.join('config/initializers/rack_attack.rb')

    assert_instance_of ActiveSupport::Cache::MemoryStore, Rack::Attack.cache.store
  end

  test 'other environments use a namespaced redis store built from the shared redis url' do
    Rails.env.stub(:test?, false) do
      load Rails.root.join('config/initializers/rack_attack.rb')
    end

    # Rack::Attack wraps the configured store in a delegating proxy.
    store = Rack::Attack.cache.store.__getobj__
    assert_instance_of ActiveSupport::Cache::RedisCacheStore, store
    assert_equal 'rack-attack', store.options[:namespace]
    expected = ActiveSupport::Cache::RedisCacheStore.new(url: Seek::RedisConfig.url)
    assert_equal expected.redis.with(&:id), store.redis.with(&:id)
  end
end
