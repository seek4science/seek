require 'test_helper'
class  DataFileWithSamplesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    login_as Factory(:user)
  end

  test "creating new data file with sample redirects to new data_file" do
     get :new
     assert_redirected_to new_data_file_path
  end
end