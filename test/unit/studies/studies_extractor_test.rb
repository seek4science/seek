require 'test_helper'

class StudiesExtractorTest < ActiveSupport::TestCase

  setup do
    @zip_file = "#{Rails.root}/test/fixtures/files/study_batch.zip"
    user_uuid = 'user_uuid'
    @data_files, @studies = Study.unzip_batch @zip_file, user_uuid
     #Factory(:study_template_content_blob)
  end

  test 'check extracted files' do

      # Extracts study file and associated data files from zip
      # file_name = params[:data][:content_blob][:tempfile].path
    user_uuid = 'user_uuid'
    data_files, studies = Study.unzip_batch @zip_file, user_uuid

    assert_same 3, data_files.count
    assert_same 1, studies.count
    assert_same true, File.exists?("#{Rails.root}/tmp/#{user_uuid}_studies_upload/#{data_files.first.name}")
    assert_same true, File.exists?("#{Rails.root}/tmp/#{user_uuid}_studies_upload/#{studies.first.name}")
  end

  test 'read study file' do

    user_uuid = 'user_uuid'
    studies_file = ContentBlob.new
    studies_file.tmp_io_object = File.open("#{Rails.root}/tmp/#{user_uuid}_studies_upload/#{@studies.first.name}")
    studies_file.original_filename = @studies.first.name.to_s
    studies_file.save!
    pp Study.extract_studies_from_file(studies_file)
  end


  test 'extract study correctly' do
    user_uuid = 'user_uuid'
    studies_file = ContentBlob.new
    studies_file.tmp_io_object = File.open("#{Rails.root}/tmp/#{user_uuid}_studies_upload/#{@studies.first.name}")
    studies_file.original_filename = @studies.first.name.to_s
    studies_file.save!

    studies = Study.extract_studies_from_file(studies_file)
    assert_same 3, studies.count

    assert_equal 'Clonal test of mapping pedigree 0504B in nursery', studies[0].title
    assert_equal 'POPYOMICS-POP2-F', studies[0].custom_metadata.data[:id]

    assert_equal 'Clonal test of mapping pedigree 0504B in nursery', studies[1].title
    assert_equal 'POPYOMICS-POP2-I', studies[1].custom_metadata.data[:id]

    assert_equal 'Clonal test of mapping pedigree 0504B in nursery', studies[2].title
    assert_equal 'POPYOMICS-POP2-UK', studies[2].custom_metadata.data[:id]

    #@extractor.extract
  end

end
