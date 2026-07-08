require 'test_helper'
require 'tmpdir'
require 'securerandom'

# End-to-end coverage of Seek::Caching::RedisWithFileOverflowStore installed as Rails.cache the way
# production.rb / development.rb wire it: built via .build (Redis 'cache' namespace + a FileStore),
# with the size threshold read live from Seek::Config through a Proc. The per-store unit tests
# (test/unit/redis_with_file_overflow_store_test.rb) inject backends and call the store directly;
# these drive the real Rails.cache mechanism and a real model call site instead, covering the
# integration gap the review flagged as L5 / Step 7.
#
# Requires a reachable Redis (the CI workflow already runs redis:8.6-alpine on localhost:6379); the
# store's own unit tests have the same requirement.
class RedisOverflowCacheTest < ActiveSupport::TestCase
  setup do
    @tmp_dir = Dir.mktmpdir
    @original_cache = Rails.cache
    @store = Seek::Caching::RedisWithFileOverflowStore.build(@tmp_dir)
    Rails.cache = @store
    @store.clear
  end

  teardown do
    @store.clear
    Rails.cache = @original_cache
    FileUtils.remove_entry(@tmp_dir)
  end

  # Incompressible payload, so its serialized (and possibly gzipped) size stays above the threshold
  # and it genuinely overflows to disk - a repetitive string would compress below the threshold and
  # land in Redis instead.
  def large_value(bytes = 4096)
    SecureRandom.hex(bytes)
  end

  def redis_backend
    @store.instance_variable_get(:@redis_store)
  end

  def file_backend
    @store.instance_variable_get(:@file_store)
  end

  test 'small values fetched through Rails.cache land in Redis, large values overflow to disk and log' do
    with_config_value(:cache_max_redis_item_size, 1.kilobyte) do
      small = Rails.cache.fetch('integration-small') { 'a small cached value' }
      assert_equal 'a small cached value', small
      assert redis_backend.exist?('integration-small')
      refute file_backend.exist?('integration-small')

      payload = large_value
      log = capture_log do
        assert_equal payload, Rails.cache.fetch('integration-large') { payload }
      end
      assert file_backend.exist?('integration-large')
      refute redis_backend.exist?('integration-large')
      assert_match(/overflow to disk key=.*integration-large/, log)
    end
  end

  test 'the size threshold is read live from Seek::Config on every write' do
    key = 'integration-threshold'
    value = large_value(1024)

    with_config_value(:cache_max_redis_item_size, 10) do
      Rails.cache.write(key, value)
      assert file_backend.exist?(key), 'a tiny threshold should route the write to disk'
      refute redis_backend.exist?(key)
    end

    with_config_value(:cache_max_redis_item_size, 1.megabyte) do
      Rails.cache.write(key, value)
      assert redis_backend.exist?(key), 'a large threshold should route the same write to Redis'
      refute file_backend.exist?(key), 'the stale disk copy should be removed'
    end

    assert_equal value, Rails.cache.read(key)
  end

  test 'Rails.cache round-trips structured values and deletes them' do
    with_config_value(:cache_max_redis_item_size, 1.kilobyte) do
      Rails.cache.write('rt-small', { total: 42, label: 'stats' })
      Rails.cache.write('rt-large', large_value)

      assert_equal({ total: 42, label: 'stats' }, Rails.cache.read('rt-small'))
      assert_equal file_backend.read('rt-large'), Rails.cache.read('rt-large')

      assert Rails.cache.delete('rt-large')
      refute Rails.cache.exist?('rt-large')
    end
  end

  test 'clear through Rails.cache empties both backends without touching other Redis namespaces' do
    guard_key = 'session:integration-guard'
    redis_backend.redis.then { |c| c.set(guard_key, 'keep-me') }

    with_config_value(:cache_max_redis_item_size, 1.kilobyte) do
      Rails.cache.write('clear-small', 'a')
      Rails.cache.write('clear-large', large_value)
    end
    assert Rails.cache.exist?('clear-small')
    assert Rails.cache.exist?('clear-large')

    Rails.cache.clear

    refute Rails.cache.exist?('clear-small')
    refute Rails.cache.exist?('clear-large')
    assert_equal 'keep-me', redis_backend.redis.then { |c| c.get(guard_key) },
                 'clear must stay scoped to the cache namespace and leave session-style keys intact'
  ensure
    redis_backend.redis.then { |c| c.del(guard_key) }
  end

  test 'delete_matched clears cache through a real call site (ContentBlob#clear_sample_type_matches)' do
    blob = FactoryBot.create(:content_blob)
    template_blob = FactoryBot.create(:content_blob)
    key = ['st-match', blob, template_blob, Seek::Config.jvm_memory_allocation,
           Seek::Config.max_extractable_spreadsheet_size]

    with_config_value(:cache_max_redis_item_size, 1.megabyte) do
      Rails.cache.write(key, true)
      assert Rails.cache.exist?(key)

      template_blob.original_filename = "#{template_blob.original_filename}-changed"
      template_blob.send(:clear_sample_type_matches)

      refute Rails.cache.exist?(key),
             'clearing sample-type matches should remove the entry through the real overflow store'
    end
  end
end
