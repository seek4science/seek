require 'test_helper'
require 'aws-sdk-s3'

class S3AdapterTest < ActiveSupport::TestCase
  BUCKET = 'test-bucket'
  PREFIX = 'assets'
  KEY    = 'abc123.dat'

  def setup
    Aws.config.update(stub_responses: true)
    @adapter = Seek::Storage::S3Adapter.new(
      bucket: BUCKET,
      prefix: PREFIX,
      region: 'us-east-1',
      access_key_id: 'test',
      secret_access_key: 'test'
    )
  end

  def teardown
    Aws.config.update(stub_responses: false)
  end

  # --- write ---

  test 'write with String body calls put_object' do
    client.stub_responses(:put_object, {})
    @adapter.write(KEY, 'hello world')
    req = client.api_requests.find { |r| r[:operation_name] == :put_object }
    assert_not_nil req
    assert_equal "#{PREFIX}/#{KEY}", req[:params][:key]
  end

  test 'write with IO body calls put_object' do
    client.stub_responses(:put_object, {})
    @adapter.write(KEY, StringIO.new('io content'))
    req = client.api_requests.find { |r| r[:operation_name] == :put_object }
    assert_not_nil req
    assert_equal "#{PREFIX}/#{KEY}", req[:params][:key]
  end

  # --- copy_from_path ---

  test 'copy_from_path reads the file and calls put_object' do
    client.stub_responses(:put_object, {})
    Tempfile.create(['seek_test', '.dat']) do |f|
      f.write('file content')
      f.flush
      @adapter.copy_from_path(f.path, KEY)
    end
    req = client.api_requests.find { |r| r[:operation_name] == :put_object }
    assert_not_nil req
    assert_equal "#{PREFIX}/#{KEY}", req[:params][:key]
  end

  # --- open ---

  test 'open returns a StringIO with the object content' do
    client.stub_responses(:get_object, { body: 'stored content' })
    io = @adapter.open(KEY)
    assert_instance_of StringIO, io
    assert_equal 'stored content', io.read
  end

  # --- exist? ---

  test 'exist? returns true when head_object succeeds' do
    client.stub_responses(:head_object, { content_length: 42 })
    assert @adapter.exist?(KEY)
  end

  test 'exist? returns false on NotFound' do
    client.stub_responses(:head_object, 'NotFound')
    assert_not @adapter.exist?(KEY)
  end

  test 'exist? returns false on NoSuchKey' do
    client.stub_responses(:head_object, 'NoSuchKey')
    assert_not @adapter.exist?(KEY)
  end

  test 'exist? returns false on Forbidden' do
    client.stub_responses(:head_object, 'Forbidden')
    assert_not @adapter.exist?(KEY)
  end

  # --- delete ---

  test 'delete calls delete_object with the correct key' do
    client.stub_responses(:delete_object, {})
    @adapter.delete(KEY)
    req = client.api_requests.find { |r| r[:operation_name] == :delete_object }
    assert_not_nil req
    assert_equal "#{PREFIX}/#{KEY}", req[:params][:key]
  end

  # --- size ---

  test 'size returns content_length from head_object' do
    client.stub_responses(:head_object, { content_length: 1024 })
    assert_equal 1024, @adapter.size(KEY)
  end

  # --- full_path ---

  test 'full_path returns nil (S3 has no local path)' do
    assert_nil @adapter.full_path(KEY)
  end

  # --- presigned_url ---

  test 'presigned_url returns a URL string containing the object key' do
    url = @adapter.presigned_url(KEY, expires_in: 60)
    assert_kind_of String, url
    assert_includes url, "#{PREFIX}/#{KEY}"
  end

  private

  def client
    @adapter.send(:instance_variable_get, :@client)
  end
end
