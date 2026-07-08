require 'test_helper'
require 'tmpdir'
require 'minitest/mock'

class RedisWithFileOverflowStoreTest < ActiveSupport::TestCase
  MAX_SIZE = 200

  def setup
    @redis_store = ActiveSupport::Cache::RedisCacheStore.new(url: 'redis://localhost:6379/15',
                                                             namespace: 'test-cache')
    @tmp_dir = Dir.mktmpdir
    @file_store = ActiveSupport::Cache::FileStore.new(@tmp_dir)
    @store = Seek::Caching::RedisWithFileOverflowStore.new(redis_store: @redis_store,
                                                           file_store: @file_store,
                                                           max_redis_item_size: MAX_SIZE)
  end

  def teardown
    @redis_store.clear
    FileUtils.remove_entry(@tmp_dir)
  end

  test 'small item is written to redis only' do
    @store.write('small-key', 'x')

    assert @redis_store.exist?('small-key')
    refute @file_store.exist?('small-key')
    assert_equal 'x', @store.read('small-key')
  end

  test 'large item is written to disk only' do
    large_value = 'x' * (MAX_SIZE * 2)
    @store.write('large-key', large_value)

    refute @redis_store.exist?('large-key')
    assert @file_store.exist?('large-key')
    assert_equal large_value, @store.read('large-key')
  end

  test 'delete removes the key from whichever backend holds it' do
    @store.write('small-key', 'x')
    @store.write('large-key', 'x' * (MAX_SIZE * 2))

    assert @store.delete('small-key')
    refute @redis_store.exist?('small-key')

    assert @store.delete('large-key')
    refute @file_store.exist?('large-key')
  end

  test 'a redis-bound write serializes once and does not re-serialize in the backend' do
    # write_entry serializes to measure size, then hands the payload to write_serialized_entry;
    # the re-serializing write_entry path on the backend must not be reached.
    @redis_store.stub(:write_entry, ->(*_a, **_k) { flunk 'redis backend re-serialized via write_entry' }) do
      @store.write('serialize-once', 'a value')
    end
    assert @redis_store.exist?('serialize-once')
    assert_equal 'a value', @store.read('serialize-once')
  end

  test 'an overflow write serializes once and does not re-serialize in the backend' do
    large_value = 'x' * (MAX_SIZE * 2)
    @file_store.stub(:write_entry, ->(*_a, **_k) { flunk 'file backend re-serialized via write_entry' }) do
      @store.write('overflow-once', large_value)
    end
    assert @file_store.exist?('overflow-once')
    assert_equal large_value, @store.read('overflow-once')
  end

  test 'a key crossing the size threshold does not leave a stale duplicate' do
    key = 'crossing-key'

    @store.write(key, 'x' * (MAX_SIZE * 2))
    assert @file_store.exist?(key)

    @store.write(key, 'x')
    assert @redis_store.exist?(key)
    refute @file_store.exist?(key)
    assert_equal 'x', @store.read(key)

    @store.write(key, 'x' * (MAX_SIZE * 2))
    assert @file_store.exist?(key)
    refute @redis_store.exist?(key)
  end

  test 'delete_matched removes matching keys from both backends using a glob string' do
    @store.write('st-match-1-a', 'x')
    @store.write('st-match-1-b', 'x' * (MAX_SIZE * 2))
    @store.write('st-match-2-a', 'x')

    @store.delete_matched('st-match-1-*')

    refute @store.exist?('st-match-1-a')
    refute @store.exist?('st-match-1-b')
    assert @store.exist?('st-match-2-a')
  end

  test 'delete_matched removes matching keys from both backends using a regexp' do
    @store.write('dashboard-1', 'x')
    @store.write('dashboard-2', 'x' * (MAX_SIZE * 2))
    @store.write('other', 'x')

    @store.delete_matched(/dashboard/)

    refute @store.exist?('dashboard-1')
    refute @store.exist?('dashboard-2')
    assert @store.exist?('other')
  end

  test 'delete_matched still deletes correctly when the server-side prefilter is active' do
    # The prefilter narrows the SCAN to keys containing the matcher's literal substring; keys that
    # do not contain it must be left untouched, and matching keys must still go regardless of which
    # backend they landed in.
    @store.write('st-match-42-a', 'x')                    # redis
    @store.write('st-match-42-b', 'x' * (MAX_SIZE * 2))   # disk
    @store.write('st-match-99-a', 'x')                    # different id, not matched by the literal
    @store.write('unrelated-key', 'x')

    @store.delete_matched('st-match-42-*')

    refute @store.exist?('st-match-42-a')
    refute @store.exist?('st-match-42-b')
    assert @store.exist?('st-match-99-a')
    assert @store.exist?('unrelated-key')
  end

  test 'guaranteed_literal_substring drops a quantified trailing character' do
    # 'st-match-12*' as a regex source is st-match-12 followed by zero-or-more '3's... i.e. the
    # trailing char before a quantifier is not guaranteed, so it must be dropped from the prefilter.
    assert_equal 'st-match-12', @store.send(:guaranteed_literal_substring, 'st-match-123*')
    assert_equal 'st-match-1', @store.send(:guaranteed_literal_substring, 'st-match-1-*')
    assert_equal 'admin_dashboard_stats', @store.send(:guaranteed_literal_substring, /admin_dashboard_stats/)
    # A leading regex anchor/metacharacter yields no usable literal, forcing a full-namespace scan.
    assert_nil @store.send(:guaranteed_literal_substring, /^foo/)
  end

  test 'redis_scan_pattern falls back to a full namespace scan without a usable literal' do
    assert_equal 'test-cache:*', @store.send(:redis_scan_pattern, /^foo/, 'test-cache:')
    assert_equal 'test-cache:*admin_dashboard_stats*',
                 @store.send(:redis_scan_pattern, /admin_dashboard_stats/, 'test-cache:')
  end

  test 'an entry already on disk in the plain FileStore format is read back cleanly' do
    @file_store.write('legacy-key', 'legacy-value')

    assert_equal 'legacy-value', @store.read('legacy-key')
  end

  test 'clear removes entries from both backends' do
    @store.write('small-key', 'x')
    @store.write('large-key', 'x' * (MAX_SIZE * 2))

    @store.clear

    refute @store.exist?('small-key')
    refute @store.exist?('large-key')
  end

  test 'cleanup removes only expired entries from the file side' do
    @store.write('expired-key', 'x' * (MAX_SIZE * 2), expires_in: 1.second)
    @store.write('fresh-key', 'x' * (MAX_SIZE * 2))
    expired_path = @file_store.send(:normalize_key, 'expired-key', {})
    fresh_path = @file_store.send(:normalize_key, 'fresh-key', {})
    sleep 1.1

    @store.cleanup

    refute File.exist?(expired_path)
    assert File.exist?(fresh_path)
  end

  test 'redis_memory_stats returns used_memory and evicted_keys' do
    stats = @store.redis_memory_stats

    assert stats.key?('used_memory')
    assert stats.key?('evicted_keys')
  end

  test 'clear does not wipe keys outside the redis namespace' do
    unrelated = ActiveSupport::Cache::RedisCacheStore.new(url: 'redis://localhost:6379/15',
                                                          namespace: 'unrelated')
    unrelated.write('session-like-key', 'do-not-touch')

    @store.write('small-key', 'x')
    @store.clear

    assert_equal 'do-not-touch', unrelated.read('session-like-key')
  ensure
    unrelated&.clear
  end

  test 'an oversized write logs an overflow entry with the key and size' do
    log_output = capture_log { @store.write('large-key', 'x' * (MAX_SIZE * 2)) }

    assert_match(/overflow to disk/, log_output)
    assert_match(/key=large-key/, log_output)
    assert_match(/size=\d+/, log_output)
  end

  test 'a normal-sized write does not log an overflow entry' do
    log_output = capture_log { @store.write('small-key', 'x') }

    refute_match(/overflow to disk/, log_output)
  end

  test 'max_redis_item_size accepts a Proc and re-evaluates it on every write' do
    threshold = MAX_SIZE
    store = Seek::Caching::RedisWithFileOverflowStore.new(redis_store: @redis_store,
                                                          file_store: @file_store,
                                                          max_redis_item_size: -> { threshold })

    store.write('proc-key', 'x' * (MAX_SIZE * 2))
    assert @file_store.exist?('proc-key')
    refute @redis_store.exist?('proc-key')

    threshold = MAX_SIZE * 3
    store.write('proc-key', 'x' * (MAX_SIZE * 2))
    assert @redis_store.exist?('proc-key')
    refute @file_store.exist?('proc-key')
  end

  test 'build constructs a working store the same way production.rb and development.rb do' do
    with_config_value(:cache_max_redis_item_size, MAX_SIZE) do
      dir = Dir.mktmpdir
      built_store = Seek::Caching::RedisWithFileOverflowStore.build(dir)

      built_store.write('build-small-key', 'x')
      built_store.write('build-large-key', 'x' * (MAX_SIZE * 2))

      assert_equal 'x', built_store.read('build-small-key')
      assert_equal 'x' * (MAX_SIZE * 2), built_store.read('build-large-key')

      built_store.clear
      FileUtils.remove_entry(dir)
    end
  end
end
