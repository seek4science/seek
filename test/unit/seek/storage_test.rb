require 'test_helper'

class StorageTest < ActiveSupport::TestCase
  def teardown
    Seek::Storage.reset!
  end

  # --- validate_config! ---

  test 'validate_config! raises ConfigurationError for unknown backend' do
    with_config(backend: 'ftp') do
      assert_raises(Seek::Storage::ConfigurationError) { Seek::Storage.validate_config! }
    end
  end

  test 'validate_config! raises ConfigurationError when S3 is missing bucket' do
    with_config(backend: 's3', access_key_id: 'key', secret_access_key: 'secret') do
      err = assert_raises(Seek::Storage::ConfigurationError) { Seek::Storage.validate_config! }
      assert_includes err.message, 'bucket'
    end
  end

  test 'validate_config! raises ConfigurationError when S3 is missing credentials' do
    with_config(backend: 's3', bucket: 'my-bucket') do
      err = assert_raises(Seek::Storage::ConfigurationError) { Seek::Storage.validate_config! }
      assert_includes err.message, 'access_key_id'
      assert_includes err.message, 'secret_access_key'
    end
  end

  test 'validate_config! does not raise for valid local config' do
    with_config(backend: 'local') do
      assert_nothing_raised { Seek::Storage.validate_config! }
    end
  end

  test 'validate_config! does not raise for valid S3 config' do
    with_config(backend: 's3', bucket: 'b', access_key_id: 'k', secret_access_key: 's') do
      assert_nothing_raised { Seek::Storage.validate_config! }
    end
  end

  # --- status ---

  test 'status returns backend: local for local config' do
    with_config(backend: 'local') do
      assert_equal({ backend: 'local' }, Seek::Storage.status)
    end
  end

  test 'status returns bucket, region and no credentials for S3 config' do
    with_config(backend: 's3', bucket: 'my-bucket', region: 'eu-west-1',
                access_key_id: 'KEY', secret_access_key: 'SECRET') do
      s = Seek::Storage.status
      assert_equal 's3',        s[:backend]
      assert_equal 'my-bucket', s[:bucket]
      assert_equal 'eu-west-1', s[:region]
      assert_not   s.key?(:access_key_id)
      assert_not   s.key?(:secret_access_key)
    end
  end

  test 'status includes endpoint when configured' do
    with_config(backend: 's3', bucket: 'b', region: 'us-east-1',
                access_key_id: 'k', secret_access_key: 's',
                endpoint: 'https://minio.example.com') do
      assert_equal 'https://minio.example.com', Seek::Storage.status[:endpoint]
    end
  end

  test 'status omits endpoint when not configured' do
    with_config(backend: 's3', bucket: 'b', region: 'us-east-1',
                access_key_id: 'k', secret_access_key: 's') do
      assert_not Seek::Storage.status.key?(:endpoint)
    end
  end

  private

  # Injects a config hash directly into Seek::Storage's memoized @config so
  # validate_config! uses it without touching seek_storage.yml or the filesystem.
  def with_config(cfg)
    Seek::Storage.reset!
    Seek::Storage.instance_variable_set(:@config, cfg)
    yield
  ensure
    Seek::Storage.reset!
  end
end
