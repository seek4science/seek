require 'test_helper'
require 'storage_stub_helper'

class CitationsTest < ActiveSupport::TestCase
  include StorageStubHelper

  def cff_blob
    cff_content = File.binread("#{Rails.root}/test/fixtures/files/CITATION.cff")
    FactoryBot.create(:content_blob, original_filename: 'CITATION.cff', data: cff_content)
  end

  test 'cff_to_csl works on the local backend (file has a path)' do
    result = nil
    assert_nothing_raised { result = Seek::Citations.cff_to_csl(cff_blob) }
    assert_not_nil result
  end

  test 'cff_to_csl reads the CFF file through the adapter on S3 (StringIO, no path)' do
    blob = cff_blob
    bytes = File.binread(blob.filepath)

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, content_length: bytes.bytesize)
      client.stub_responses(:get_object, body: bytes)
      # Previously crashed on S3: CFF::File.read(blob.file) with a StringIO
      # ("no implicit conversion of StringIO into String").
      result = nil
      assert_nothing_raised { result = Seek::Citations.cff_to_csl(blob) }
      assert_not_nil result, 'expected a citation parsed from the CFF file streamed off S3'
    end
  end
end
