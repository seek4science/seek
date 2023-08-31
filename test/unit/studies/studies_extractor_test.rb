require 'test_helper'

class StudiesExtractorTest < ActiveSupport::TestCase

  setup do
    @zip_file = "#{Rails.root}/test/fixtures/files/study_batch.zip"
    user_uuid = 'user_uuid'
    @data_files, @studies = StudyBatchUpload.unzip_batch @zip_file, user_uuid
     #FactoryBot.create(:study_template_content_blob)
  end

  test 'check extracted files' do

      # Extracts study file and associated data files from zip
      # file_name = params[:data][:content_blob][:tempfile].path
    user_uuid = 'user_uuid'
    data_files, studies = StudyBatchUpload.unzip_batch @zip_file, user_uuid

    assert_same 3, data_files.count
    assert_same 1, studies.count
    assert_same true, File.exist?("#{Rails.root}/tmp/#{user_uuid}_studies_upload/#{data_files.first.name}")
    assert_same true, File.exist?("#{Rails.root}/tmp/#{user_uuid}_studies_upload/#{studies.first.name}")

    FileUtils.rm_r("#{Rails.root}/tmp/#{user_uuid}_studies_upload/")
  end

  test 'read study file' do

    FactoryBot.create(:study_custom_metadata_type_for_MIAPPE)
    user_uuid = 'user_uuid'
    studies_file = ContentBlob.new
    studies_file.tmp_io_object = File.open("#{Rails.root}/tmp/#{user_uuid}_studies_upload/#{@studies.first.name}")
    studies_file.original_filename = @studies.first.name.to_s
    studies_file.save!
    StudyBatchUpload.extract_studies_from_file(studies_file)

    FileUtils.rm_r("#{Rails.root}/tmp/#{user_uuid}_studies_upload/")
  end

  test 'extract study correctly' do
    user_uuid = 'user_uuid'
    FactoryBot.create(:study_custom_metadata_type_for_MIAPPE)
    studies_file = ContentBlob.new
    studies_file.tmp_io_object = File.open("#{Rails.root}/tmp/#{user_uuid}_studies_upload/#{@studies.first.name}")
    studies_file.original_filename = @studies.first.name.to_s
    studies_file.save!

    studies = StudyBatchUpload.extract_studies_from_file(studies_file)
    assert_same 3, studies.count

    assert_equal 'Clonal test of mapping pedigree 0504B in nursery', studies[0].title
    assert_equal 'POPYOMICS-POP2-F', studies[0].custom_metadata.data[:id]

    assert_equal 'Clonal test of mapping pedigree 0504B in nursery', studies[1].title
    assert_equal 'POPYOMICS-POP2-I', studies[1].custom_metadata.data[:id]

    assert_equal 'Clonal test of mapping pedigree 0504B in nursery', studies[2].title
    assert_equal 'POPYOMICS-POP2-UK', studies[2].custom_metadata.data[:id]

    FileUtils.rm_r("#{Rails.root}/tmp/#{user_uuid}_studies_upload/")
    #@extractor.extract
  end


  test 'validate date format correctly' do
    valid_date_1 = '2020-08-15'
    valid_date_2 = '1994-03-30'
    wrong_date_1 = '20-08-15'
    wrong_date_2 = '2020-08-32'
    wrong_date_3 = '2020-15-08'
    wrong_date_4 = '2020/08/15'

    assert_equal true, StudyBatchUpload.validate_date(valid_date_1)
    assert_equal true, StudyBatchUpload.validate_date(valid_date_2)
    assert_equal false, StudyBatchUpload.validate_date(wrong_date_1)
    assert_equal false, StudyBatchUpload.validate_date(wrong_date_2)
    assert_equal false, StudyBatchUpload.validate_date(wrong_date_3)
    assert_equal false, StudyBatchUpload.validate_date(wrong_date_4)

  end


  test 'get right licence from file' do
    user_uuid = 'user_uuid'
    FactoryBot.create(:study_custom_metadata_type_for_MIAPPE)
    studies_file = ContentBlob.new
    studies_file.tmp_io_object = File.open("#{Rails.root}/tmp/#{user_uuid}_studies_upload/#{@studies.first.name}")
    studies_file.original_filename = @studies.first.name.to_s
    studies_file.save!

    licence = StudyBatchUpload.get_license_id(studies_file)
    assert_equal licence, 'CC-BY-SA-4.0'

  end

  test 'check if string is normalized ' do

    my_string = 'Here is-my_test STRING'
    normalize_output = StudyBatchUpload.normalize_license_id(my_string)
    assert_not_equal normalize_output, 'Here is-my_test STRING'
    assert_not_equal normalize_output, 'here is my test string'
    assert_not_equal normalize_output, 'Hereismyteststring'
    assert_equal normalize_output, 'HEREISMYTESTSTRING'
  end


end
