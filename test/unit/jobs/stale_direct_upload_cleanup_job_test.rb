require 'test_helper'
require 'storage_stub_helper'

class StaleDirectUploadCleanupJobTest < ActiveSupport::TestCase
  include StorageStubHelper

  test 'removes old staged uploads on the S3 backend' do
    with_stubbed_s3_storage do |_dat, _converted, uploads|
      client = s3_client(uploads)
      staged = [{ key: 'uploads/old', last_modified: 2.days.ago },
                { key: 'uploads/fresh', last_modified: 5.minutes.ago }]
      client.stub_responses(:list_objects_v2, { contents: staged })
      client.stub_responses(:delete_object, {})

      StaleDirectUploadCleanupJob.perform_now

      deleted = client.api_requests.select { |r| r[:operation_name] == :delete_object }.map { |r| r[:params][:key] }
      assert_equal ['uploads/old'], deleted
    end
  end

  test 'does nothing on the local backend' do
    Seek::Storage.stub(:direct_upload_enabled?, false) do
      Seek::Storage.stub(:upload_adapter, ->(*) { flunk 'the staging adapter must not be touched' }) do
        assert_nothing_raised { StaleDirectUploadCleanupJob.perform_now }
      end
    end
  end
end
