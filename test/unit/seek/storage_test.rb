require 'test_helper'
require 'storage_stub_helper'

class StorageTest < ActiveSupport::TestCase
  include StorageStubHelper

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

  # --- direct upload ---

  test 'direct_upload_enabled? is true only for the S3 backend' do
    with_config(backend: 'local') { assert_not Seek::Storage.direct_upload_enabled? }
    with_s3_config { assert Seek::Storage.direct_upload_enabled? }
  end

  test 'upload_adapter is nil on the local backend' do
    with_config(backend: 'local') { assert_nil Seek::Storage.upload_adapter }
  end

  test 'upload_adapter is an S3Adapter on the uploads prefix' do
    with_s3_config do
      adapter = Seek::Storage.upload_adapter
      assert_kind_of Seek::Storage::S3Adapter, adapter
      assert_equal 'uploads/abc.dat', adapter.full_key('abc.dat')
    end
  end

  test 'upload_adapter is memoised and distinct from the assets and converted adapters' do
    with_s3_config do
      assert_same Seek::Storage.upload_adapter, Seek::Storage.upload_adapter
      assert_not_same Seek::Storage.upload_adapter, Seek::Storage.adapter_for('dat')
      assert_not_same Seek::Storage.upload_adapter, Seek::Storage.adapter_for('pdf')
    end
  end

  test 'reset! clears the memoised upload_adapter' do
    with_s3_config do
      first = Seek::Storage.upload_adapter
      Seek::Storage.reset!
      Seek::Storage.instance_variable_set(:@config, s3_config)
      assert_not_same first, Seek::Storage.upload_adapter
    end
  end

  test 'with_stubbed_s3_storage yields the uploads adapter and enables direct upload' do
    with_stubbed_s3_storage do |dat, converted, uploads|
      assert_equal 'assets/x.dat',    dat.full_key('x.dat')
      assert_equal 'converted/x.pdf', converted.full_key('x.pdf')
      assert_equal 'uploads/x',       uploads.full_key('x')
      assert_same uploads, Seek::Storage.upload_adapter
      assert Seek::Storage.direct_upload_enabled?
    end
  end

  test 'with_stubbed_s3_storage still works for callers taking two adapters' do
    with_stubbed_s3_storage do |dat, converted|
      assert_equal 'assets/x.dat', dat.full_key('x.dat')
      assert_equal 'converted/x.txt', converted.full_key('x.txt')
    end
  end

  private

  def s3_config
    { backend: 's3', bucket: 'b', region: 'us-east-1', access_key_id: 'k', secret_access_key: 's' }
  end

  def with_s3_config(&block)
    require 'aws-sdk-s3'
    Aws.config.update(stub_responses: true)
    with_config(s3_config, &block)
  ensure
    Aws.config.update(stub_responses: false)
  end

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
