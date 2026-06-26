require 'test_helper'
require 'storage_stub_helper'

# Field JAR needs a real local file. On S3 the blob has no local path, so the
# generators must stream a temporary copy. This runs the real JAR against a copy streamed from a
# stubbed S3 backend and checks the output matches the local-backend run.
class RightfieldS3Test < ActiveSupport::TestCase
  include StorageStubHelper
  include Rightfield::Rightfield

  test 'generate_rightfield_csv reads the blob from S3 via a temporary copy' do
    data_file = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:rightfield_master_template))
    xls_bytes = File.binread(data_file.content_blob.filepath)

    # Baseline: run on the local backend (real JAR reads the on-disk file).
    expected = generate_rightfield_csv(data_file)
    refute_empty expected, 'expected the local RightField run to produce CSV output'
    Rails.cache.clear # force the S3 run to re-execute rather than hit the cached result

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, content_length: xls_bytes.bytesize)
      client.stub_responses(:get_object, body: xls_bytes)

      result = generate_rightfield_csv(DataFile.find(data_file.id))
      assert_equal expected, result, 'RightField CSV from S3 should match the local-backend output'
    end
  end
end
