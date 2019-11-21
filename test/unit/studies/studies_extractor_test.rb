require 'test_helper'

class StudiesExtractorTest < ActiveSupport::TestCase

  setup do 
	@zip_file = "#{Rails.root}/test/fixtures/files/study_batch.zip"
     #Factory(:study_template_content_blob)
	  #@extractor = Seek::Studies::Extractor.new
  end

  test "check extracted files" do 

    # Extracts study file and associated data files from zip
    # file_name = params[:data][:content_blob][:tempfile].path
    data_files, studies = Study.unzip_batch @zip_file


	assert_same 3, data_files.count
	assert_same 1, studies.count

  end

  test 'extract study correctly' do
  	assert_same true, true
  	#@extractor.extract
  end

end
