require 'test_helper'

class AdminControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  test "should show rebrand" do
    login_as(:quentin)
    get :rebrand
    assert_response :success
  end

  test "only admin can restart the server" do
    login_as(:aaron)
    post :restart_server
    assert_not_nil flash[:error]
  end

  test "should show features enabled" do
    login_as(:quentin)
    get :features_enabled
    assert_response :success
  end

  test "should show pagination" do
    login_as(:quentin)
    get :pagination
    assert_response :success
  end

  test "should show others" do
    login_as(:quentin)
    get :others
    assert_response :success
  end

  test "visible to admin" do
    login_as(:quentin)
    get :show
    assert_response :success
    assert_nil flash[:error]
  end

  test "invisible to non admin" do
    login_as(:aaron)
    get :show
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test 'string to boolean' do
    login_as(:quentin)
    post :update_features_enabled, :events_enabled => '1'
    assert_equal true, Seek::Config.events_enabled
  end

  test 'invalid email address' do
    login_as(:quentin)
    post :update_others, :pubmed_api_email => 'quentin', :crossref_api_email => 'quentin@example.com', :tag_threshold => '', :max_visible_tags => '20'
    assert_not_nil flash[:error]
  end

  test 'should input integer' do
    login_as(:quentin)
    post :update_others, :pubmed_api_email => 'quentin@example.com', :crossref_api_email => 'quentin@example.com', :tag_threshold => '', :max_visible_tags => '20'
    assert_not_nil flash[:error]
  end

  test 'should input positive integer' do
    login_as(:quentin)
    post :update_others, :pubmed_api_email => 'quentin@example.com', :crossref_api_email => 'quentin@example.com', :tag_threshold => '1', :max_visible_tags => '0'
    assert_not_nil flash[:error]
  end


  test "update admins" do
    login_as(:quentin)
    quentin=people(:quentin_person)
    aaron=people(:aaron_person)
    
    assert quentin.is_admin?
    assert !aaron.is_admin?

    post :update_admins,:admins=>[aaron.id]

    quentin.reload
    aaron.reload

    assert !quentin.is_admin?
    assert aaron.is_admin?
    
  end

  test "get project content stats" do
    login_as(:quentin)
    xml_http_request :get, :get_stats,{:id=>"contents"}
    assert_response :success
  end

end
