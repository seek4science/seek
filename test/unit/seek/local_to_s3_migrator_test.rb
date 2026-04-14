require 'test_helper'
require 'seek/storage/local_to_s3_migrator'

# Minimal stand-in for ContentBlob — only the fields the migrator reads.
MigratorBlobStub = Struct.new(:uuid, :file_size) do
  def storage_key(format = 'dat') = "#{uuid}.#{format}"
end

# Wraps an array so it responds to find_each (the only method migrator calls on scope).
class MigratorBlobScope
  def initialize(blobs) = @blobs = blobs
  def find_each(&block) = @blobs.each(&block)
end

class LocalToS3MigratorTest < ActiveSupport::TestCase
  def setup
    Aws.config.update(stub_responses: true)
    @dat_dir    = Dir.mktmpdir('seek_migrator_dat_')
    @conv_dir   = Dir.mktmpdir('seek_migrator_conv_')
    @local_dat  = Seek::Storage::LocalAdapter.new(base_path: @dat_dir)
    @local_conv = Seek::Storage::LocalAdapter.new(base_path: @conv_dir)
    @s3_dat     = build_s3('assets')
    @s3_conv    = build_s3('converted')
    @output     = StringIO.new
  end

  def teardown
    Aws.config.update(stub_responses: false)
    FileUtils.rm_rf(@dat_dir)
    FileUtils.rm_rf(@conv_dir)
  end

  test 'copies original dat file to S3 and reports copied' do
    blob = write_local_dat('abc-001', 'hello world')
    stub_upload(@s3_dat, 11)
    result = run_migrator([blob])
    assert_equal 1, result.copied
    assert_equal 0, result.failed
  end

  test 'copies persisted pdf derivative to S3' do
    blob = write_local_dat('abc-002', 'original')
    write_local_conv('abc-002', 'pdf', '%PDF-fake')
    stub_upload(@s3_dat, 8)
    stub_upload(@s3_conv, 9)
    assert_equal 2, run_migrator([blob]).copied
  end

  test 'dry-run reports work without uploading' do
    blob = write_local_dat('abc-003', 'content')
    s3_client(@s3_dat).stub_responses(:head_object, ['NotFound'])
    result = run_migrator([blob], dry_run: true)
    assert_equal 1, result.copied
    assert_includes @output.string, 'DRY-RUN'
    assert s3_client(@s3_dat).api_requests.none? { |r| r[:operation_name] == :put_object },
           'put_object must not be called in dry-run'
  end

  test 'skips blob already on S3 with matching size' do
    blob = write_local_dat('abc-004', 'hello')
    s3_client(@s3_dat).stub_responses(:head_object, [{ content_length: 5 }])
    result = run_migrator([blob])
    assert_equal 1, result.skipped
    assert_equal 0, result.copied
  end

  test 'counts missing when local dat file does not exist' do
    result = run_migrator([MigratorBlobStub.new('abc-005', 0)])
    assert_equal 1, result.missing
    assert_includes @output.string, 'MISSING'
  end

  test 'counts failure when existing S3 object has wrong size' do
    blob = write_local_dat('abc-006', 'hello')
    s3_client(@s3_dat).stub_responses(:head_object, [{ content_length: 999 }])
    result = run_migrator([blob])
    assert_equal 1, result.failed
    assert_includes @output.string, 'ERROR'
  end

  test 'continues processing after a single blob error' do
    stub_upload(@s3_dat, 12)
    result = run_migrator([write_local_dat('abc-007', 'good content'), MigratorBlobStub.new('abc-008', 0)])
    assert_equal 1, result.copied
    assert_equal 1, result.missing
  end

  test 'reruns are idempotent: already-migrated blobs are skipped' do
    blob = write_local_dat('abc-009', 'idempotent')
    s3_client(@s3_dat).stub_responses(:head_object, [{ content_length: 10 }])
    2.times { assert_equal 1, run_migrator([blob]).skipped }
  end

  test 'result summary string includes all counters' do
    result = Seek::Storage::LocalToS3Migrator::Result.new(copied: 3, skipped: 1, missing: 0, failed: 1)
    assert_includes result.summary, 'Copied: 3'
    assert_includes result.summary, 'Skipped: 1'
    assert_includes result.summary, 'Failed: 1'
  end

  private

  def run_migrator(blobs, dry_run: false)
    migrator = Seek::Storage::LocalToS3Migrator.new(
      dry_run: dry_run, output: @output,
      local_dat: @local_dat, local_conv: @local_conv,
      s3_dat: @s3_dat, s3_conv: @s3_conv
    )
    migrator.run(scope: MigratorBlobScope.new(blobs))
  end

  def build_s3(prefix)
    Seek::Storage::S3Adapter.new(bucket: 'test-bucket', prefix: prefix,
                                 region: 'us-east-1', access_key_id: 'test',
                                 secret_access_key: 'test')
  end

  def stub_upload(adapter, uploaded_size)
    s3_client(adapter).stub_responses(:head_object, ['NotFound', { content_length: uploaded_size }])
    s3_client(adapter).stub_responses(:put_object, [{}])
  end

  def write_local_dat(uuid, content)
    File.write(File.join(@dat_dir, "#{uuid}.dat"), content)
    MigratorBlobStub.new(uuid, content.bytesize)
  end

  def write_local_conv(uuid, format, content) = File.write(File.join(@conv_dir, "#{uuid}.#{format}"), content)

  def s3_client(adapter) = adapter.send(:instance_variable_get, :@client)
end
