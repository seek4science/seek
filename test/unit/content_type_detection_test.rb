require 'test_helper'

class ContentTypeDetectionTest < ActiveSupport::TestCase
  include Seek::ContentTypeDetection

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

  test 'csv and tsv have their own extraction size limit' do
    csv_blob = FactoryBot.create :csv_content_blob
    tsv_blob = FactoryBot.create :tsv_content_blob
    xlsx_blob = FactoryBot.create :xlsx_content_blob

    with_config_value(:max_extractable_csv_size, 0) do
      refute csv_blob.is_extractable_csv?
      refute csv_blob.is_extractable_spreadsheet?
      refute is_extractable_spreadsheet?(tsv_blob)
      assert xlsx_blob.is_extractable_spreadsheet?, 'Excel files should not be affected by the CSV limit'
    end

    with_config_value(:max_extractable_spreadsheet_size, 0) do
      assert csv_blob.is_extractable_csv?
      assert csv_blob.is_extractable_spreadsheet?, 'CSV files should not be affected by the Excel limit'
      assert is_extractable_spreadsheet?(tsv_blob)
      refute xlsx_blob.is_extractable_spreadsheet?
    end

    refute xlsx_blob.is_extractable_csv?

    with_config_value(:max_extractable_csv_size, 3) do
      with_config_value(:max_extractable_spreadsheet_size, 7) do
        assert_equal 3, csv_blob.extractable_spreadsheet_size_limit
        assert_equal 3, extractable_spreadsheet_size_limit(tsv_blob)
        assert_equal 7, xlsx_blob.extractable_spreadsheet_size_limit
      end
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
