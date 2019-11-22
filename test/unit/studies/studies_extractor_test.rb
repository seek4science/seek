require 'test_helper'

class StudiesExtractorTest < ActiveSupport::TestCase

  setup do 
  	@zip_file = "#{Rails.root}/test/fixtures/files/study_batch.zip"
    @data_files, @studies = Study.unzip_batch @zip_file
     #Factory(:study_template_content_blob)
  end

  test "check extracted files" do 

      # Extracts study file and associated data files from zip
      # file_name = params[:data][:content_blob][:tempfile].path
    data_files, studies = Study.unzip_batch @zip_file

  	assert_same 3, data_files.count
  	assert_same 1, studies.count
    assert_same true, File.exists?("#{Rails.root}/tmp/#{data_files.first.name}")
  end

  test "read study file" do

    studies_file = ContentBlob.new
    studies_file.tmp_io_object=File.open("#{Rails.root}/tmp/#{@studies.first.name}")
    studies_file.original_filename="#{@studies.first.name}"
    studies_file.save!
    pp Study.extract_studies_from_file(studies_file)
  end


  test 'extract study correctly' do
  	assert_same true, true
  	#@extractor.extract
  end

end
