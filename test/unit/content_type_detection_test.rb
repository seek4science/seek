require 'test_helper'
  require 'storage_stub_helper'

class ContentTypeDetectionTest < ActiveSupport::TestCase
  include Seek::ContentTypeDetection
  include StorageStubHelper

  test 'is_xls' do
    blob = FactoryBot.create :spreadsheet_content_blob
    assert blob.is_xls?
    assert is_xls?(blob)

    blob = FactoryBot.create :xlsx_content_blob
    assert !blob.is_xls?
    assert !is_xls?(blob)
  end

  test 'is_xlsx' do
    blob = FactoryBot.create :xlsx_content_blob
    assert blob.is_xlsx?
    assert is_xlsx?(blob)

    blob = FactoryBot.create :spreadsheet_content_blob
    assert !blob.is_xlsx?
    assert !is_xlsx?(blob)
  end

  test 'is_excel' do
    blob = FactoryBot.create :spreadsheet_content_blob
    assert blob.is_excel?
    assert is_excel?(blob)

    blob = FactoryBot.create :xlsx_content_blob
    assert blob.is_excel?
    assert is_excel?(blob)

    blob = FactoryBot.create :xlsm_content_blob
    assert blob.is_excel?(blob)
    assert is_excel?(blob)

    blob = FactoryBot.create :doc_content_blob
    assert !blob.is_excel?(blob)
    assert !is_excel?(blob)
  end

  test 'is_extractable_spreadsheet' do
    blob = FactoryBot.create :spreadsheet_content_blob
    assert blob.is_extractable_spreadsheet?
    assert is_extractable_spreadsheet?(blob)

    blob = FactoryBot.create :xlsx_content_blob
    assert blob.is_extractable_spreadsheet?
    assert is_extractable_spreadsheet?(blob)

    blob = FactoryBot.create :xlsm_content_blob
    assert blob.is_extractable_spreadsheet?
    assert is_extractable_spreadsheet?(blob)

    blob = FactoryBot.create :doc_content_blob
    refute blob.is_extractable_spreadsheet?
    refute is_extractable_spreadsheet?(blob)

    blob = FactoryBot.create :csv_content_blob
    assert blob.is_extractable_spreadsheet?
    assert is_extractable_spreadsheet?(blob)

    blob = FactoryBot.create :tsv_content_blob
    assert blob.is_extractable_spreadsheet?
    assert is_extractable_spreadsheet?(blob)

    with_config_value(:max_extractable_spreadsheet_size, 0) do
      blob = FactoryBot.create :xlsx_content_blob
      refute blob.is_extractable_spreadsheet?
      refute is_extractable_spreadsheet?(blob)
    end
  end

  test 'is_extractable_excel' do
    blob = FactoryBot.create :spreadsheet_content_blob
    assert blob.is_extractable_excel?
    assert is_extractable_excel?(blob)

    blob = FactoryBot.create :xlsx_content_blob
    assert blob.is_extractable_excel?
    assert is_extractable_excel?(blob)

    blob = FactoryBot.create :xlsm_content_blob
    assert blob.is_extractable_excel?
    assert is_extractable_excel?(blob) 

    blob = FactoryBot.create :doc_content_blob
    refute blob.is_extractable_excel?
    refute is_extractable_excel?(blob)

    blob = FactoryBot.create :csv_content_blob
    refute blob.is_extractable_excel?
    refute is_extractable_excel?(blob)

    blob = FactoryBot.create :tsv_content_blob
    refute blob.is_extractable_excel?
    refute is_extractable_excel?(blob)

    with_config_value(:max_extractable_spreadsheet_size, 0) do
      blob = FactoryBot.create :xlsx_content_blob
      refute blob.is_extractable_excel?
      refute is_extractable_excel?(blob)
    end
  end

  test 'is_supported_spreadsheet_format' do
    blob = FactoryBot.create :spreadsheet_content_blob
    assert blob.is_supported_spreadsheet_format?
    assert is_supported_spreadsheet_format?(blob)

    blob = FactoryBot.create :xlsx_content_blob
    assert blob.is_supported_spreadsheet_format?
    assert is_supported_spreadsheet_format?(blob)

    blob = FactoryBot.create :xlsm_content_blob
    assert blob.is_supported_spreadsheet_format?
    assert is_supported_spreadsheet_format?(blob)

    blob = FactoryBot.create :csv_content_blob
    assert blob.is_supported_spreadsheet_format?
    assert is_supported_spreadsheet_format?(blob)

    blob = FactoryBot.create :doc_content_blob
    refute blob.is_supported_spreadsheet_format?
    refute is_supported_spreadsheet_format?(blob)

    with_config_value(:max_extractable_spreadsheet_size, 0) do
      blob = FactoryBot.create :xlsx_content_blob
      assert blob.is_supported_spreadsheet_format?
      assert is_supported_spreadsheet_format?(blob)
    end
  end

  test 'is_sbml' do
    blob = FactoryBot.create :teusink_model_content_blob
    assert is_sbml?(blob)
    assert !is_jws_dat?(blob)
    assert blob.is_sbml?
    assert !blob.is_jws_dat?
    assert !blob.is_xgmml?
  end

  test 'is_sbml reads content through the adapter on S3 (no local file)' do
    blob = FactoryBot.create :teusink_model_content_blob
    sbml_bytes = File.binread(blob.filepath)

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, content_length: sbml_bytes.bytesize)
      client.stub_responses(:get_object, body: sbml_bytes)
      # check_content must read via the adapter, not a local filepath.
      assert blob.is_sbml?, 'expected is_sbml? to detect SBML content streamed from S3'
      assert_not blob.is_jws_dat?
    end
  end

  test 'mime_magic content type detection does not crash on S3 (no local file)' do
    blob = FactoryBot.create :teusink_model_content_blob
    bytes = File.binread(blob.filepath)

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, content_length: bytes.bytesize)
      client.stub_responses(:get_object, body: bytes)
      # Reproduces the COPASI-upload crash: extension-less detection falls back to
      # sniffing magic bytes, which used to File.open(filepath) and raise Errno::ENOENT on S3.
      assert_nothing_raised { blob.send(:mime_magic_content_type) }
    end
  end

  # Regression: during create_version, model-type detection runs on blobs that are not yet saved,
  # so data_io_object returns the blob's live @tmp_io_object (the pending upload). check_content
  # must neither close nor consume it, or the subsequent save-to-storage write fails with
  test 'check_content does not close or consume a pending tmp_io_object' do
    sbml_bytes = File.binread(FactoryBot.create(:teusink_model_content_blob).filepath)

    # StringIO case (mirrors a retained blob carried into a new version on S3).
    blob = ContentBlob.new(original_filename: 'model.xml', content_type: 'text/xml')
    blob.tmp_io_object = StringIO.new(sbml_bytes)
    assert blob.is_sbml?, 'detection should work on a pending StringIO tmp_io_object'
    io = blob.data_io_object
    assert_not io.closed?, 'check_content must not close the pending tmp_io_object'
    io.rewind
    assert_equal sbml_bytes, io.read, 'pending content must remain fully readable for the save write'

    # ActionDispatch::Http::UploadedFile case (the freshly uploaded file): delegates read/rewind
    # but not each_line - the old each_line scan raised NoMethodError here.
    Tempfile.create(['upload', '.xml']) do |tmp|
      tmp.binmode
      tmp.write(sbml_bytes)
      tmp.rewind
      uploaded = ActionDispatch::Http::UploadedFile.new(tempfile: tmp, filename: 'model.xml', type: 'text/xml')
      blob2 = ContentBlob.new(original_filename: 'model.xml', content_type: 'text/xml')
      blob2.tmp_io_object = uploaded
      assert_nothing_raised { blob2.is_sbml? }
      assert blob2.is_sbml?, 'detection should work on a pending UploadedFile tmp_io_object'
      uploaded.rewind
      assert_equal sbml_bytes, uploaded.read, 'uploaded file must remain readable for the save write'
    end
  end

  test 'is_jws_dat' do
    blob = FactoryBot.create :teusink_jws_model_content_blob
    assert !is_sbml?(blob)
    assert is_jws_dat?(blob)
    assert !blob.is_sbml?
    assert blob.is_jws_dat?
    assert !blob.is_xgmml?
  end

  test 'is_xgmml' do
    blob = FactoryBot.create :xgmml_content_blob
    assert blob.is_xgmml?
    assert !blob.is_sbml?
  end

  test 'is supported no longer relies on extension' do
    blob = FactoryBot.create :teusink_model_content_blob
    blob.original_filename = 'teusink.txt'
    blob.dump_data_to_file
    assert blob.is_sbml?
    assert !blob.is_jws_dat?

    blob = FactoryBot.create :teusink_jws_model_content_blob
    blob.original_filename = 'jws.txt'
    blob.dump_data_to_file
    assert !blob.is_sbml?
    assert blob.is_jws_dat?
  end

  test 'matlab files recognised' do
    blob1 = FactoryBot.create(:content_blob, original_filename:'file.mat')
    blob2 = FactoryBot.create(:content_blob, original_filename:'file.mat')

    [blob1,blob2].each do |blob|
      assert_equal 'Matlab file',blob.human_content_type, "wrong human name for #{blob.original_filename}"
      assert_equal 'application/matlab',blob.content_type, "wrong human name for #{blob.original_filename}"
      assert blob.is_text?
    end
  end
end
