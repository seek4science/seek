require 'test_helper'

class ContentTypeDetectionTest < ActiveSupport::TestCase
  include Seek::ContentTypeDetection

  test 'is_xls' do
    blob = Factory :spreadsheet_content_blob
    assert blob.is_xls?
    assert is_xls?(blob)

    blob = Factory :xlsx_content_blob
    assert !blob.is_xls?
    assert !is_xls?(blob)
  end

  test 'is_xlsx' do
    blob = Factory :xlsx_content_blob
    assert blob.is_xlsx?
    assert is_xlsx?(blob)

    blob = Factory :spreadsheet_content_blob
    assert !blob.is_xlsx?
    assert !is_xlsx?(blob)
  end

  test 'is_excel' do
    blob = Factory :spreadsheet_content_blob
    assert blob.is_excel?
    assert is_excel?(blob)

    blob = Factory :xlsx_content_blob
    assert blob.is_excel?
    assert is_excel?(blob)

    blob = Factory :xlsm_content_blob
    assert blob.is_excel?(blob)
    assert is_excel?(blob)

    blob = Factory :doc_content_blob
    assert !blob.is_excel?(blob)
    assert !is_excel?(blob)
  end

  test 'is_extractable_spreadsheet' do
    blob = Factory :spreadsheet_content_blob
    assert blob.is_extractable_spreadsheet?
    assert is_extractable_spreadsheet?(blob)

    blob = Factory :xlsx_content_blob
    assert blob.is_extractable_spreadsheet?
    assert is_extractable_spreadsheet?(blob)

    blob = Factory :xlsm_content_blob
    assert blob.is_extractable_spreadsheet?
    assert is_extractable_spreadsheet?(blob)

    blob = Factory :doc_content_blob
    refute blob.is_extractable_spreadsheet?
    refute is_extractable_spreadsheet?(blob)

    blob = Factory :csv_content_blob
    assert blob.is_extractable_spreadsheet?
    assert is_extractable_spreadsheet?(blob)

    blob = Factory :tsv_content_blob
    assert blob.is_extractable_spreadsheet?
    assert is_extractable_spreadsheet?(blob)

    with_config_value(:max_extractable_spreadsheet_size, 0) do
      blob = Factory :xlsx_content_blob
      refute blob.is_extractable_spreadsheet?
      refute is_extractable_spreadsheet?(blob)
    end
  end

  test 'is_extractable_excel' do
    blob = Factory :spreadsheet_content_blob
    assert blob.is_extractable_excel?
    assert is_extractable_excel?(blob)

    blob = Factory :xlsx_content_blob
    assert blob.is_extractable_excel?
    assert is_extractable_excel?(blob)

    blob = Factory :xlsm_content_blob
    assert blob.is_extractable_excel?
    assert is_extractable_excel?(blob) 

    blob = Factory :doc_content_blob
    refute blob.is_extractable_excel?
    refute is_extractable_excel?(blob)

    blob = Factory :csv_content_blob
    refute blob.is_extractable_excel?
    refute is_extractable_excel?(blob)

    blob = Factory :tsv_content_blob
    refute blob.is_extractable_excel?
    refute is_extractable_excel?(blob)

    with_config_value(:max_extractable_spreadsheet_size, 0) do
      blob = Factory :xlsx_content_blob
      refute blob.is_extractable_excel?
      refute is_extractable_excel?(blob)
    end
  end

  test 'is_supported_spreadsheet_format' do
    blob = Factory :spreadsheet_content_blob
    assert blob.is_supported_spreadsheet_format?
    assert is_supported_spreadsheet_format?(blob)

    blob = Factory :xlsx_content_blob
    assert blob.is_supported_spreadsheet_format?
    assert is_supported_spreadsheet_format?(blob)

    blob = Factory :xlsm_content_blob
    assert blob.is_supported_spreadsheet_format?
    assert is_supported_spreadsheet_format?(blob)

    blob = Factory :csv_content_blob
    assert blob.is_supported_spreadsheet_format?
    assert is_supported_spreadsheet_format?(blob)

    blob = Factory :doc_content_blob
    refute blob.is_supported_spreadsheet_format?
    refute is_supported_spreadsheet_format?(blob)

    with_config_value(:max_extractable_spreadsheet_size, 0) do
      blob = Factory :xlsx_content_blob
      assert blob.is_supported_spreadsheet_format?
      assert is_supported_spreadsheet_format?(blob)
    end
  end

  test 'is_sbml' do
    blob = Factory :teusink_model_content_blob
    assert is_sbml?(blob)
    assert !is_jws_dat?(blob)
    assert blob.is_sbml?
    assert !blob.is_jws_dat?
    assert !blob.is_xgmml?
  end

  test 'is_jws_dat' do
    blob = Factory :teusink_jws_model_content_blob
    assert !is_sbml?(blob)
    assert is_jws_dat?(blob)
    assert !blob.is_sbml?
    assert blob.is_jws_dat?
    assert !blob.is_xgmml?
  end

  test 'is_xgmml' do
    blob = Factory :xgmml_content_blob
    assert blob.is_xgmml?
    assert !blob.is_sbml?
  end

  test 'is supported no longer relies on extension' do
    blob = Factory :teusink_model_content_blob
    blob.original_filename = 'teusink.txt'
    blob.dump_data_to_file
    assert blob.is_sbml?
    assert !blob.is_jws_dat?

    blob = Factory :teusink_jws_model_content_blob
    blob.original_filename = 'jws.txt'
    blob.dump_data_to_file
    assert !blob.is_sbml?
    assert blob.is_jws_dat?
  end

  test 'matlab files recognised' do
    blob1 = Factory(:content_blob, original_filename:'file.mat')
    blob2 = Factory(:content_blob, original_filename:'file.mat')

    [blob1,blob2].each do |blob|
      assert_equal 'Matlab file',blob.human_content_type, "wrong human name for #{blob.original_filename}"
      assert_equal 'application/matlab',blob.content_type, "wrong human name for #{blob.original_filename}"
      assert blob.is_text?
    end
  end
end
