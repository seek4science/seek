require 'test_helper'

class UuidsControllerTest < ActionController::TestCase
  fixtures :all
  include AuthenticatedTestHelper
  
  def setup
    login_as(:quentin)
  end
  
  test "show" do
    teusink=models(:teusink)
    get :show, :id=>teusink.uuid
    assert_redirected_to teusink
  end
  
  test "show2" do
    assay=assays(:metabolomics_assay)
    get :show, :id=>assay.uuid
    assert_redirected_to assay
  end
  
end
