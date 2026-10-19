require 'test_helper'

# Exercises Rack::Attack throttling against the store the app is configured with - a real Redis via
# Seek::RackAttackStore - rather than the injected MockRedis backends the unit tests use
# (test/unit/rack_attack_test.rb). This is where the counters meet a genuine Redis, covering the
# INCR/EXPIRE behaviour and TTLs a mock cannot vouch for.
#
# Integration tests are configured with this store by test_helper.rb, so Rack::Attack.cache.store is
# already the Redis one here. A reachable Redis is needed (the CI workflow runs redis:8.6-alpine on
# localhost:6379, and the session store needs it regardless) and the test skips without one.
class RackAttackRedisTest < ActionDispatch::IntegrationTest
  LIMIT = 3
  PERIOD = 1.minute
  CLIENT_IP = '10.0.0.1'.freeze
  OTHER_IP = '10.0.0.2'.freeze

  setup do
    skip('these tests need a running Redis server') unless redis_available?
    Rack::Attack.clear_configuration
    Rack::Attack.throttle('integration/ip', limit: LIMIT, period: PERIOD, &:ip)
    # Counters outlive the request that wrote them, so clear any left by an earlier run - otherwise
    # a count carried over within the same period would throttle a client these tests expect to be
    # under the limit. Only the rack-attack namespace is touched, not the cache or session keys.
    store.clear
  end

  teardown do
    Rack::Attack.clear_configuration
    load Rails.root.join('config/initializers/rack_attack.rb')
  end

  def store
    Rack::Attack.cache.store
  end

  def redis_available?
    store.redis.with(&:ping) == 'PONG'
  rescue StandardError
    false
  end

  # Rack::Attack's own key format, so the assertions look at the keys the middleware really writes.
  def counter_key(ip = CLIENT_IP)
    "#{Rack::Attack.cache.prefix}:#{Time.now.to_i / PERIOD.to_i}:integration/ip:#{ip}"
  end

  def request_status(ip: CLIENT_IP)
    get '/', headers: { 'REMOTE_ADDR' => ip }
    response.status
  end

  test 'integration tests are configured with the redis-backed store' do
    assert_instance_of ActiveSupport::Cache::RedisCacheStore, store.__getobj__
    assert_equal Seek::RackAttackStore::NAMESPACE, store.__getobj__.options[:namespace]
  end

  test 'requests are throttled and the counter is held in redis with a ttl' do
    LIMIT.times { refute_equal 429, request_status }
    assert_equal 429, request_status

    assert_equal LIMIT + 1, store.read(counter_key).to_i
    ttl = store.__getobj__.redis.with { |redis| redis.ttl("#{Seek::RackAttackStore::NAMESPACE}:#{counter_key}") }
    assert ttl.positive?, "expected the counter to expire, got a TTL of #{ttl}"
    assert ttl <= PERIOD.to_i
  end

  test 'a second store against the same redis sees the count, so instances share a limit' do
    LIMIT.times { request_status }

    # Rack::Attack writes counters with raw: true, so read them the same way.
    other_instance = Seek::RackAttackStore.build
    assert_equal LIMIT, other_instance.read(counter_key, raw: true).to_i
  end

  test 'throttling is keyed on the client, so other addresses are unaffected' do
    (LIMIT + 1).times { request_status }
    assert_equal 429, request_status

    refute_equal 429, request_status(ip: OTHER_IP)
  end
end
