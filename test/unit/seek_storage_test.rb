require 'test_helper'

class SeekStorageTest < ActiveSupport::TestCase
  def setup
    Seek::Storage.reset!
  end

  def teardown
    Seek::Storage.reset!
  end

  test 'adapter_for dat returns a LocalAdapter with asset_filestore_path' do
    adapter = Seek::Storage.adapter_for('dat')
    assert_instance_of Seek::Storage::LocalAdapter, adapter
    assert_equal Seek::Config.asset_filestore_path, adapter.full_path('').chomp('/')
  end

  test 'adapter_for pdf returns a LocalAdapter with converted_filestore_path' do
    adapter = Seek::Storage.adapter_for('pdf')
    assert_instance_of Seek::Storage::LocalAdapter, adapter
    assert_equal Seek::Config.converted_filestore_path, adapter.full_path('').chomp('/')
  end

  test 'adapter_for txt also returns a LocalAdapter with converted_filestore_path' do
    adapter = Seek::Storage.adapter_for('txt')
    assert_instance_of Seek::Storage::LocalAdapter, adapter
    assert_equal Seek::Config.converted_filestore_path, adapter.full_path('').chomp('/')
  end

  test 'adapter_for dat is memoized — same object on repeated calls' do
    assert_same Seek::Storage.adapter_for('dat'), Seek::Storage.adapter_for('dat')
  end

  test 'adapter_for pdf and adapter_for txt return the same object (shared :converted key)' do
    assert_same Seek::Storage.adapter_for('pdf'), Seek::Storage.adapter_for('txt')
  end

  test 'reset! clears memoized adapters so a new instance is returned' do
    first = Seek::Storage.adapter_for('dat')
    Seek::Storage.reset!
    second = Seek::Storage.adapter_for('dat')
    refute_same first, second
  end

  test 'load_config returns local backend when seek_storage.yml is absent' do
    # Temporarily rename the file to simulate absence
    config_path = Rails.root.join('config', 'seek_storage.yml')
    hidden_path = Rails.root.join('config', 'seek_storage.yml.bak')
    File.rename(config_path, hidden_path)
    Seek::Storage.reset!

    adapter = Seek::Storage.adapter_for('dat')
    assert_instance_of Seek::Storage::LocalAdapter, adapter
  ensure
    File.rename(hidden_path, config_path) if File.exist?(hidden_path)
    Seek::Storage.reset!
  end
end
