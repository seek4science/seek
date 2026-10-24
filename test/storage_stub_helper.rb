# Reusable helpers for exercising the S3 storage backend in tests without a real S3 server.
#
# Usage:
#   include StorageStubHelper
#   with_stubbed_s3_storage do |dat_adapter, converted_adapter|
#     # storage_adapter(format) now returns a stubbed S3Adapter for every blob
#     ...
#   end
#
# Built on the same approach as test/unit/seek/content_extraction_test.rb:
# a real Seek::Storage::S3Adapter wrapping an AWS SDK client in stub_responses mode.
require 'minitest/mock'

module StorageStubHelper
  def build_s3_adapter(prefix = 'assets')
    require 'aws-sdk-s3'
    Seek::Storage::S3Adapter.new(
      bucket: 'test-bucket',
      prefix: prefix,
      region: 'us-east-1',
      access_key_id: 'test',
      secret_access_key: 'test'
    )
  end

  def s3_client(adapter)
    adapter.send(:instance_variable_get, :@client)
  end

  # Routes Seek::Storage through stubbed S3 adapters for the duration of the block, as if the S3
  # backend were configured:
  #   adapter_for('dat')      -> the assets adapter
  #   adapter_for(<other>)    -> the converted adapter
  #   upload_adapter          -> the uploads (direct-upload staging) adapter
  #   direct_upload_enabled?  -> true
  # Yields all three adapters so the caller can configure stub_responses on their clients.
  # Existing callers that take only |dat, converted| keep working.
  def with_stubbed_s3_storage
    require 'aws-sdk-s3'
    Aws.config.update(stub_responses: true)
    dat = build_s3_adapter('assets')
    converted = build_s3_adapter('converted')
    uploads = build_s3_adapter('uploads')
    stub_seek_storage(dat, converted, uploads) { yield dat, converted, uploads }
  ensure
    Aws.config.update(stub_responses: false)
  end

  private

  def stub_seek_storage(dat, converted, uploads, &block)
    Seek::Storage.stub(:adapter_for, ->(format = 'dat') { format == 'dat' ? dat : converted }) do
      Seek::Storage.stub(:upload_adapter, uploads) do
        Seek::Storage.stub(:direct_upload_enabled?, true, &block)
      end
    end
  end
end
