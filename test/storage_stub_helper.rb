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

  # Routes Seek::Storage.adapter_for through stubbed S3 adapters for the duration of the block.
  # 'dat' resolves to the assets adapter; any other format to the converted adapter.
  # Yields both adapters so the caller can configure stub_responses on their clients.
  def with_stubbed_s3_storage
    require 'aws-sdk-s3'
    Aws.config.update(stub_responses: true)
    dat = build_s3_adapter('assets')
    converted = build_s3_adapter('converted')
    Seek::Storage.stub(:adapter_for, ->(format = 'dat') { format == 'dat' ? dat : converted }) do
      yield dat, converted
    end
  ensure
    Aws.config.update(stub_responses: false)
  end
end
