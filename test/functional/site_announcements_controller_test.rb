require 'test_helper'

class SiteAnnouncementsControllerTest < ActionController::TestCase
  fixtures :users, :people

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:site_announcements)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should show' do
    announcement = Factory(:feed_announcement)
    assert_not_nil announcement.announcer
    get :show, id: announcement
    assert_response :success
  end

  test 'should get edit' do
    announcement = Factory(:feed_announcement)
    assert_not_nil announcement.announcer
    get :edit, id: announcement
    assert_response :success
  end

  test 'should create' do
    assert_difference('SiteAnnouncement.count') do
      post :create, site_announcement: { title: 'fred' }
    end
    assert_equal users(:quentin).person, assigns(:site_announcement).announcer
  end

  test 'should destroy' do
    ann = Factory(:site_announcement)
    assert_difference('SiteAnnouncement.count', -1) do
      delete :destroy, id: ann.id
    end
  end

  test 'should email registered users' do
    NotifieeInfo.delete_all
    people = []
    (0...5).to_a.each do
      people << Factory(:person)
    end

    assert_equal 5, people.size

    registered_receivers = Person.registered.select { |p| p.notifiee_info.try :receive_notifications? }
    assert registered_receivers.count >= 5

    assert_emails(registered_receivers.count) do
      post :create, site_announcement: { title: 'fred', email_notification: true }
      site_announcement = assigns(:site_announcement)
      assert SendAnnouncementEmailsJob.new(site_announcement.id, 1).exists?
      first_id = people.collect(&:notifiee_info).collect(&:id).min
      SendAnnouncementEmailsJob.new(site_announcement.id, first_id).perform
    end
  end

  test 'should handle deleted notifiee person' do
    person = Person.with_group.find { |p| p.notifiee_info.try :receive_notifications? }
    if person
      person.delete
      assert_emails(NotifieeInfo.where(receive_notifications: true).count - 1) do
        post :create, site_announcement: { title: 'fred', email_notification: true }
      end
    end
  end

  test 'should not destroy' do
    ann = Factory(:feed_announcement)
    login_as(Factory(:person))
    assert_no_difference('SiteAnnouncement.count') do
      delete :destroy, id: ann.id
    end

    assert_not_nil flash[:error]
  end

  test 'should update' do
    ann = Factory(:feed_announcement)
    put :update, id: ann, site_announcement: { title: 'bob' }
    ann = SiteAnnouncement.find(ann.id)
    assert_equal 'bob', ann.title
  end

  test 'should not get new' do
    login_as(Factory(:person))
    get :new
    assert_response :redirect
    assert_redirected_to(root_url)
    assert_not_nil flash[:error]
  end

  test 'should not get edit' do
    login_as(Factory(:person))
    announcement = Factory(:feed_announcement)
    assert_not_nil announcement.announcer
    get :edit, id: announcement
    assert_response :redirect
    assert_redirected_to(root_url)
    assert_not_nil flash[:error]
  end

  test 'should not create' do
    login_as(Factory(:person))
    assert_no_difference('SiteAnnouncement.count') do
      post :create, site_announcement: { title: 'fred' }
    end
    assert_response :redirect
    assert_redirected_to(root_url)
    assert_not_nil flash[:error]
  end

  test 'should not update' do
    login_as(:aaron)
    ann = Factory(:feed_announcement)
    put :update, id: ann, site_announcement: { title: 'bob' }

    assert_response :redirect
    assert_redirected_to(root_url)
    assert_not_nil flash[:error]

    ann = SiteAnnouncement.find(ann.id)
    assert_equal 'a feed announcement', ann.title
  end

  test 'feed with empty announcements' do
    login_as(Factory(:person))
    SiteAnnouncement.delete_all
    get :feed, format: 'atom'
    assert_response :success
  end

  test 'should get the headline announcements on the index page' do
    Factory :headline_announcement
    assert !SiteAnnouncement.all.select(&:is_headline).empty?
    get :index
    assert_response :success
    assert_select 'div.announcement_list div.announcement span.announcement_title', text: /a headline announcement/, count: 1
  end

  test 'should only show feeds when feed_only passed' do
    Factory :headline_announcement, show_in_feed: false, title: 'a headline announcement'
    Factory :headline_announcement, show_in_feed: true, title: 'a headline announcement also in feed'
    get :index, feed_only: true
    assert_response :success
    assert_select 'div.announcement_list div.announcement span.announcement_title', text: 'a headline announcement', count: 0
    assert_select 'div.announcement_list div.announcement span.announcement_title', text: 'a headline announcement also in feed', count: 1
  end

  test 'handle notification_settings' do
    # valid key
    key = Factory(:notifiee_info).unique_key
    get :notification_settings, key: key
    assert_response :success
    assert_nil flash[:error]
    assert_select 'input[checked=checked][id=receive_notifications]'

    # invalid key
    key = 'random'
    get :notification_settings, key: key
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end
end
