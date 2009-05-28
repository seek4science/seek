require 'test_helper'

class ExperimentalConditionsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test "should not get edit option for downloadable only sop" do
    sop=sops(:downloadable_sop)
    get :index,:sop_id=>sop.id
    assert_select 'img[title="Start editing"]',:count=>0
    assert_select 'div[id="edit_on"]',:count=>0
    assert_select 'div[id="edit_off"]',:count=>0
  end

  test "should get edit option for editable sop" do
    sop=sops(:editable_sop)
    get :index,:sop_id=>sop.id
    assert_select 'img[title="Start editing"]',:count=>1
    assert_select 'div[id="edit_on"]',:count=>1
    assert_select 'div[id="edit_off"]',:count=>1
  end

  test "should get edit option for owners downloadable sop" do
    login_as(:owner_of_my_first_sop)
    sop=sops(:downloadable_sop)
    get :index,:sop_id=>sop.id
    assert_select 'img[title="Start editing"]',:count=>1
    assert_select 'div[id="edit_on"]',:count=>1
    assert_select 'div[id="edit_off"]',:count=>1
  end



end
