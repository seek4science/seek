require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def test_should_be_accesable_to_seek_even_if_not_logged_in
    get :index
    assert_response :success
  end

  def test_title
    login_as(:quentin)
    get :index
    assert_select "title",:text=>/The Sysmo SEEK.*/, :count=>1
  end

  test "should get feedback form" do
    login_as(:quentin)
    get :feedback
    assert_response :success
  end  

  test "admin link not visible to non admin" do
    login_as(:aaron)
    get :index
    assert_response :success
    assert_select "a#adminmode[href=?]",admin_path,:count=>0
  end

  test "admin tab visible to admin" do
    login_as(:quentin)
    get :index
    assert_response :success
    assert_select "a#adminmode[href=?]",admin_path,:count=>1
  end

  test "SOP tab should be capitalized" do
    login_as(:quentin)
    get :index
    assert_select "div.section>li>a[href=?]","/sops",:text=>"SOPs",:count=>1
  end

  test "SOP upload option should be capitlized" do
    login_as(:quentin)
    get :index
    assert_select "select#new_resource_type",:count=>1 do
      assert_select "option[value=?]","sop",:text=>"SOP"
    end
  end

  test "hidden items do not appear in recent items" do
    model = Factory :model, :policy => Factory(:private_policy), :title => "A title"

    login_as(:quentin)
    get :index

    #difficult to use assert_select, because of the way the tabbernav tabs are constructed with javascript onLoad
    assert !@response.body.include?(model.title)
  end

  test 'root should route to sign_up when no user, otherwise to home' do
    User.find(:all).each do |u|
      u.delete
    end
    get :index
    assert_redirected_to :controller => 'users', :action => 'new'

    Factory(:user)
    get :index
    assert_response :success
  end

  test 'should hide the forum tab for unlogin user' do
    logout
    get :index, :controller => 'home'
    assert_response :success
    assert_select 'a',:text=>/Forum/,:count=>0

    login_as(:quentin)
    get :index
    assert_response :success
    assert_select 'a',:text=>/Forum/,:count=>1
  end
end
