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

  test "index" do
    p=Factory :person
    df=Factory :data_file,:contributor=>p
    tool=Factory :tool,:value=>"fork",:source=>p.user,:annotatable=>p
    tag=Factory :tag,:value=>"fishing",:source=>p.user,:annotatable=>df

    login_as p.user
    get :index
    assert_response :success

    assert_select "div#super_tag_cloud a[href=?]",show_ann_path(tag),:text=>"fishing",:count=>1
    assert_select "div#super_tag_cloud a[href=?]",show_ann_path(tool),:text=>"fork",:count=>1
  end

  test "dont show duplicates for same tag for expertise and tools" do
    p=Factory :person
    tool=Factory :tool,:value=>"xxxxx",:source=>p.user,:annotatable=>p
    exp=Factory :expertise,:value=>"xxxxx",:source=>p.user,:annotatable=>p

    login_as p.user
    get :index
    assert_response :success


    get :show,:id=>tool
    assert_response :success
    assert_select "div.list_items_container" do
      assert_select "a",:text=>p.name,:count=>1
    end
  end

end