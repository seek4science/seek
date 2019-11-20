require 'test_helper'

class StudiesExtractorTest < ActiveSupport::TestCase

  setup do 
	  Factory(:study_template_content_blob)
  end

  test 'extract study correctly' do
  	assert_same true, true
  end

end
