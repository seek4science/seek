require 'test_helper'
require 'tmpdir'
require 'mock_redis'

class CacheOverflowCleanupJobTest < ActiveSupport::TestCase
  MAX_SIZE = 200

  test 'removes only expired entries from the file overflow side' do
    redis_store = ActiveSupport::Cache::RedisCacheStore.new(redis: MockRedis.new,
                                                            namespace: 'test-cache-overflow-job')
    tmp_dir = Dir.mktmpdir
    file_store = ActiveSupport::Cache::FileStore.new(tmp_dir)
    store = Seek::Caching::RedisWithFileOverflowStore.new(redis_store: redis_store,
                                                          file_store: file_store,
                                                          max_redis_item_size: MAX_SIZE)

    store.write('expired-key', 'x' * (MAX_SIZE * 2), expires_in: 1.second)
    store.write('fresh-key', 'x' * (MAX_SIZE * 2))
    expired_path = file_store.send(:normalize_key, 'expired-key', {})
    fresh_path = file_store.send(:normalize_key, 'fresh-key', {})
    sleep 1.1

    original_cache = Rails.cache
    Rails.cache = store
    CacheOverflowCleanupJob.perform_now
    Rails.cache = original_cache

    refute File.exist?(expired_path)
    assert File.exist?(fresh_path)
  ensure
    redis_store&.clear
    FileUtils.remove_entry(tmp_dir) if tmp_dir
  end

  test 'logs redis memory stats when the store supports it' do
    redis_store = ActiveSupport::Cache::RedisCacheStore.new(redis: MockRedis.new,
                                                            namespace: 'test-cache-overflow-job')
    tmp_dir = Dir.mktmpdir
    store = Seek::Caching::RedisWithFileOverflowStore.new(redis_store: redis_store,
                                                          file_store: ActiveSupport::Cache::FileStore.new(tmp_dir),
                                                          max_redis_item_size: MAX_SIZE)

    original_cache = Rails.cache
    Rails.cache = store
    log_output = capture_log { CacheOverflowCleanupJob.perform_now }
    Rails.cache = original_cache

    assert_match(/Redis memory stats/, log_output)
    assert_match(/used_memory/, log_output)
    assert_match(/evicted_keys/, log_output)
  ensure
    redis_store&.clear
    FileUtils.remove_entry(tmp_dir) if tmp_dir
  end

  test 'does not error when the store does not support redis_memory_stats' do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    log_output = capture_log { CacheOverflowCleanupJob.perform_now }
    Rails.cache = original_cache

    refute_match(/Redis memory stats/, log_output)
    refute_match(/Could not fetch Redis memory stats/, log_output)
  end
end
