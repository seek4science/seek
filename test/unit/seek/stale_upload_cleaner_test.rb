require 'test_helper'
require 'storage_stub_helper'

class StaleUploadCleanerTest < ActiveSupport::TestCase
  include StorageStubHelper

  def setup
    require 'aws-sdk-s3'
    Aws.config.update(stub_responses: true)
    @adapter = build_s3_adapter('uploads')
    @client = s3_client(@adapter)
  end

  def teardown
    Aws.config.update(stub_responses: false)
  end

  test 'deletes staged objects older than the limit and keeps newer ones' do
    stub_listing('old' => 3.days.ago, 'fresh' => 1.hour.ago, 'ancient' => 30.days.ago)
    @client.stub_responses(:delete_object, {})

    result = Seek::Storage::StaleUploadCleaner.new(max_age: 1.day, adapter: @adapter).run

    assert_equal 3, result.examined
    assert_equal 2, result.stale
    assert_equal 2, result.deleted
    assert_equal %w[uploads/ancient uploads/old], deleted_keys.sort
  end

  test 'keeps an object exactly at the limit, which may still belong to an open form' do
    travel_to Time.utc(2026, 6, 1, 12, 0, 0) do
      stub_listing('borderline' => Time.utc(2026, 5, 31, 12, 0, 0))
      result = Seek::Storage::StaleUploadCleaner.new(max_age: 1.day, adapter: @adapter).run
      assert_equal 0, result.stale
      assert_empty deleted_keys
    end
  end

  test 'dry run reports what would go but deletes nothing' do
    stub_listing('old' => 3.days.ago, 'fresh' => 1.hour.ago)

    result = Seek::Storage::StaleUploadCleaner.new(max_age: 1.day, dry_run: true, adapter: @adapter).run

    assert_equal 1, result.stale
    assert_equal 0, result.deleted
    assert_empty deleted_keys
    assert_includes result.summary, 'dry run'
  end

  test 'honours a custom age limit' do
    stub_listing('two_hours' => 2.hours.ago, 'ten_minutes' => 10.minutes.ago)
    @client.stub_responses(:delete_object, {})

    result = Seek::Storage::StaleUploadCleaner.new(max_age: 1.hour, adapter: @adapter).run

    assert_equal ['uploads/two_hours'], deleted_keys
    assert_equal 1, result.deleted
  end

  test 'does nothing without a staging adapter, as on the local backend' do
    result = Seek::Storage::StaleUploadCleaner.new(adapter: nil).run
    assert_equal 0, result.examined
    assert_equal 0, result.deleted
  end

  test 'logs each stale object when given a logger' do
    stub_listing('old' => 3.days.ago)
    @client.stub_responses(:delete_object, {})
    io = StringIO.new
    Seek::Storage::StaleUploadCleaner.new(max_age: 1.day, adapter: @adapter, logger: Logger.new(io)).run
    assert_includes io.string, 'deleting old'
  end

  test 'summary states the counts' do
    stub_listing('old' => 3.days.ago, 'fresh' => 1.hour.ago)
    @client.stub_responses(:delete_object, {})
    summary = Seek::Storage::StaleUploadCleaner.new(max_age: 1.day, adapter: @adapter).run.summary
    assert_includes summary, '2 object(s) examined'
    assert_includes summary, '1 older than the limit'
    assert_includes summary, '1 deleted'
  end

  private

  def stub_listing(keys_with_times)
    contents = keys_with_times.map { |key, time| { key: "uploads/#{key}", last_modified: time } }
    @client.stub_responses(:list_objects_v2, { contents: contents })
  end

  def deleted_keys
    @client.api_requests.select { |r| r[:operation_name] == :delete_object }.map { |r| r[:params][:key] }
  end
end
