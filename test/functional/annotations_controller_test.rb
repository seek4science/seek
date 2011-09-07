require 'test_helper'
class AnnotationsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    login_as Factory(:user,:person => Factory(:person))
  end

  test "show for expertise tag" do
    p=Factory :person
    exp=Factory :expertise,:value=>"golf",:source=>p.user,:annotatable=>p
    get :show,:id=>exp
    assert_response :success
  end

  test "show for tools tag" do
    p=Factory :person
    tool=Factory :tool,:value=>"spade",:source=>p.user,:annotatable=>p
    get :show,:id=>tool
    assert_response :success
  end

  test "show for general tag" do
    df=Factory :data_file
    tag=Factory :tag,:value=>"a tag",:source=>User.current_user,:annotatable=>df
    get :show,:id=>tag
    assert_response :success
  end

end