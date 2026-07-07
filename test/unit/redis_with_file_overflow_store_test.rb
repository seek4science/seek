require 'test_helper'
require 'tmpdir'

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

  test 'an entry already on disk in the plain FileStore format is read back cleanly' do
    @file_store.write('legacy-key', 'legacy-value')

    assert_equal 'legacy-value', @store.read('legacy-key')
  end
end
