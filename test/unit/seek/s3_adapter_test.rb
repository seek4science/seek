require 'test_helper'
require 'aws-sdk-s3'

class S3AdapterTest < ActiveSupport::TestCase
  BUCKET = 'test-bucket'.freeze
  PREFIX = 'assets'.freeze
  KEY    = 'abc123.dat'.freeze

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

  test 'presigned_url overrides response filename and content type so downloads open correctly' do
    url = @adapter.presigned_url(KEY, expires_in: 60,
                                 filename: 'My Report.xlsx',
                                 content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                 disposition: 'attachment')
    decoded = CGI.unescape(url)
    assert_includes decoded, 'response-content-disposition='
    assert_includes decoded, 'attachment'
    assert_includes decoded, 'My Report.xlsx'
    assert_includes decoded, 'response-content-type='
    assert_includes decoded, 'spreadsheetml.sheet'
  end

  test 'presigned_url omits response overrides when filename and content type are absent' do
    decoded = CGI.unescape(@adapter.presigned_url(KEY, expires_in: 60))
    assert_not_includes decoded, 'response-content-disposition='
    assert_not_includes decoded, 'response-content-type='
  end

  # --- presigned_upload_url ---

  test 'presigned_upload_url returns a signed PUT URL for the prefixed object key' do
    url = @adapter.presigned_upload_url(KEY, expires_in: 120)
    assert_kind_of String, url
    assert_includes url, "#{PREFIX}/#{KEY}"
    assert_includes url, 'X-Amz-Signature='
    assert_includes url, 'X-Amz-Expires=120'
  end

  test 'presigned_upload_url signs the content type when given' do
    with_type    = CGI.unescape(@adapter.presigned_upload_url(KEY, content_type: 'text/plain'))
    without_type = CGI.unescape(@adapter.presigned_upload_url(KEY))
    assert_includes with_type, 'content-type'
    assert_not_includes without_type, 'content-type'
  end

  test 'presigned_upload_url defaults to a 15 minute expiry' do
    assert_includes @adapter.presigned_upload_url(KEY), 'X-Amz-Expires=900'
  end

  # --- copy_object ---

  test 'copy_object below the single-copy limit issues one CopyObject with REPLACE' do
    @adapter.copy_object('uploads/tok', KEY, size: 10 * 1024 * 1024)
    copies = client.api_requests.select { |r| r[:operation_name] == :copy_object }
    assert_equal 1, copies.size
    params = copies.first[:params]
    assert_equal "#{BUCKET}/uploads/tok", params[:copy_source]
    assert_equal BUCKET, params[:bucket]
    assert_equal "#{PREFIX}/#{KEY}", params[:key]
    assert_equal 'REPLACE', params[:metadata_directive]
    assert_empty(client.api_requests.select { |r| r[:operation_name] == :create_multipart_upload })
  end

  test 'copy_object at exactly the single-copy limit still uses one CopyObject' do
    @adapter.copy_object('uploads/tok', KEY, size: Seek::Storage::S3Adapter::SINGLE_COPY_LIMIT)
    ops = client.api_requests.map { |r| r[:operation_name] }
    assert_equal [:copy_object], ops
  end

  test 'copy_object above the single-copy limit performs a multipart copy' do
    @adapter.copy_object('uploads/tok', KEY, size: Seek::Storage::S3Adapter::SINGLE_COPY_LIMIT + 1)
    ops = client.api_requests.map { |r| r[:operation_name] }
    assert_not_includes ops, :copy_object
    assert_equal 1, ops.count(:create_multipart_upload)
    assert_operator ops.count(:upload_part_copy), :>, 1
    assert_equal 1, ops.count(:complete_multipart_upload)
    create = client.api_requests.find { |r| r[:operation_name] == :create_multipart_upload }[:params]
    assert_equal "#{PREFIX}/#{KEY}", create[:key]
    part = client.api_requests.find { |r| r[:operation_name] == :upload_part_copy }[:params]
    assert_equal "#{BUCKET}/uploads/tok", part[:copy_source]
  end

  test 'presigned_upload_url signs against the public endpoint when one is configured' do
    adapter = Seek::Storage::S3Adapter.new(
      bucket: BUCKET, prefix: 'uploads', region: 'us-east-1',
      access_key_id: 'test', secret_access_key: 'test',
      endpoint: 'http://seaweedfs:8333', public_endpoint: 'https://s3.example.org',
      force_path_style: true
    )
    url = adapter.presigned_upload_url(KEY)
    assert url.start_with?("https://s3.example.org/#{BUCKET}/uploads/#{KEY}"), url
    assert_not_includes url, 'seaweedfs:8333'
  end

  test 'test_connection returns success when list_objects_v2 succeeds' do
    client.stub_responses(:list_objects_v2, { contents: [] })
    assert @adapter.test_connection[:success]
  end

  test 'test_connection returns failure hash when NoSuchBucket' do
    client.stub_responses(:list_objects_v2, 'NoSuchBucket')
    assert_not @adapter.test_connection[:success]
  end

  test 'test_connection returns failure hash when AccessDenied' do
    client.stub_responses(:list_objects_v2, 'AccessDenied')
    result = @adapter.test_connection
    assert_not result[:success]
    assert_includes result[:message], 'access_key_id'
  end

  # --- each_object ---

  test 'each_object lists the prefix and yields keys without it' do
    client.stub_responses(:list_objects_v2, {
                            contents: [
                              { key: "#{PREFIX}/one.dat", last_modified: Time.utc(2026, 1, 1) },
                              { key: "#{PREFIX}/two.dat", last_modified: Time.utc(2026, 1, 2) }
                            ]
                          })
    seen = @adapter.each_object.to_a
    assert_equal [['one.dat', Time.utc(2026, 1, 1)], ['two.dat', Time.utc(2026, 1, 2)]], seen
    req = client.api_requests.find { |r| r[:operation_name] == :list_objects_v2 }
    assert_equal "#{PREFIX}/", req[:params][:prefix]
  end

  test 'each_object follows the listing across pages' do
    first_page = { contents: [{ key: "#{PREFIX}/a.dat", last_modified: Time.utc(2026, 1, 1) }],
                   is_truncated: true, next_continuation_token: 'page-2' }
    second_page = { contents: [{ key: "#{PREFIX}/b.dat", last_modified: Time.utc(2026, 1, 1) }],
                    is_truncated: false }
    client.stub_responses(:list_objects_v2, [first_page, second_page])
    keys = @adapter.each_object.map { |key, _modified| key }
    assert_equal %w[a.dat b.dat], keys
    lists = client.api_requests.select { |r| r[:operation_name] == :list_objects_v2 }
    assert_equal 2, lists.size
    assert_equal 'page-2', lists.last[:params][:continuation_token]
  end

  test 'each_object yields nothing for an empty prefix' do
    client.stub_responses(:list_objects_v2, { contents: [] })
    assert_empty @adapter.each_object.to_a
  end

  private

  def client
    @adapter.send(:instance_variable_get, :@client)
  end
end
