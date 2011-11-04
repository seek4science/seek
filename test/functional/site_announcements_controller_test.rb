require 'test_helper'

class SiteAnnouncementsControllerTest < ActionController::TestCase
  
  fixtures :users,:people,:site_announcements

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:site_announcements)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should show" do
    announcement=site_announcements(:feed)
    assert_not_nil announcement.announcer
    get :show,:id=>announcement
    assert_response :success
  end
  
  test "should get edit" do
    announcement=site_announcements(:feed)
    assert_not_nil announcement.announcer
    get :edit,:id=>announcement
    assert_response :success
  end
  
  test "should create" do
    assert_difference("SiteAnnouncement.count") do
      post :create,:site_announcement=>{:title=>"fred"}
    end    
    assert_equal users(:quentin).person,assigns(:site_announcement).announcer
  end
  
  test "should destroy" do
    assert_difference("SiteAnnouncement.count",-1) do
      delete :destroy,:id=>site_announcements(:feed)
    end    
  end

  test "should email registered users" do
    assert_emails(Person.registered.select {|p| p.notifiee_info.try :receive_notifications?}.count) do
      post :create,:site_announcement=>{:title=>"fred", :email_notification => true}
    end
  end
  
  test "should not destroy" do
    login_as(:aaron)
    assert_no_difference("SiteAnnouncement.count") do
      delete :destroy,:id=>site_announcements(:feed)
    end   
    
    assert_not_nil flash[:error]
  end
  
  test "should update" do
    ann=site_announcements(:feed)
    put :update,:id=>ann,:site_announcement=>{:title=>"bob"}
    ann=SiteAnnouncement.find(ann.id)
    assert_equal "bob",ann.title
  end
  
  test "should not get new" do
    login_as(:aaron)
    get :new
    assert_response :redirect
    assert_redirected_to(root_url)    
    assert_not_nil flash[:error]
  end
  
  test "should not get edit" do
    login_as(:aaron)
    announcement=site_announcements(:feed)
    assert_not_nil announcement.announcer
    get :edit,:id=>announcement
    assert_response :redirect
    assert_redirected_to(root_url)
    assert_not_nil flash[:error]
  end
  
  test "should not create" do
    login_as(:aaron)
    assert_no_difference("SiteAnnouncement.count") do
      post :create,:site_announcement=>{:title=>"fred"}
    end    
    assert_response :redirect
    assert_redirected_to(root_url)
    assert_not_nil flash[:error]
  end
  
  test "should not update" do
    login_as(:aaron)
    ann=site_announcements(:feed)
    put :update,:id=>ann,:site_announcement=>{:title=>"bob"}
    
    assert_response :redirect
    assert_redirected_to(root_url)
    assert_not_nil flash[:error]
    
    ann=SiteAnnouncement.find(ann.id)    
    assert_equal "a feed announcement",ann.title
    
  end

  test "feed with empty announcements" do
    login_as(:aaron)
    SiteAnnouncement.delete_all
    get :feed,:format=>"atom"
    assert_response :success
  end
  
end
