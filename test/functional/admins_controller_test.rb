require 'test_helper'

class AdminsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  test "should show rebrand" do
    login_as(:quentin)
    get :rebrand
    assert_response :success
  end

  test "non admin cannot restart the server" do
    login_as(Factory(:user))
    post :restart_server
    assert_not_nil flash[:error]
  end

  test "admin can restart the server" do
    login_as(Factory(:admin).user)
    post :restart_server
    assert_nil flash[:error]
  end

  test "get registration form" do
    login_as Factory(:admin).user
    get :registration_form
    assert_response :success
  end

  test "non admin cannot restart the delayed job" do
    login_as(Factory(:user))
    post :restart_delayed_job
    assert_not_nil flash[:error]
  end

  test "admin can restart the delayed job" do
    login_as(Factory(:admin).user)
    post :restart_delayed_job
    assert_nil flash[:error]
  end

  test "none admin not get registration form" do
    login_as Factory(:person).user
    get :registration_form
    assert !User.current_user.person.is_admin?
    assert_redirected_to root_path
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

  test 'update visible tags and threshold' do
    login_as(:quentin)
    Seek::Config.max_visible_tags=2
    Seek::Config.tag_threshold=2
    post :update_others, :tag_threshold => '8', :max_visible_tags => '9'
    assert_equal 8,Seek::Config.tag_threshold
    assert_equal 9,Seek::Config.max_visible_tags
  end

  test 'invalid email address' do
    login_as(:quentin)
    post :update_others, :pubmed_api_email => 'quentin', :crossref_api_email => 'quentin@example.com', :tag_threshold => '1', :max_visible_tags => '20'
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
    assert aaron.is_admin?
  end

  test "get project content stats" do
    login_as(:quentin)
    xml_http_request :get, :get_stats,{:id=>"contents"}
    assert_response :success
  end

  test "The configuration should stay the same after test_email_configuration" do
    login_as(:quentin)
    smtp_hash = ActionMailer::Base.smtp_settings
    raise_delivery_errors_setting = ActionMailer::Base.raise_delivery_errors
    xml_http_request :post, :test_email_configuration,{:address=>"127.0.0.1", :port => '25', :domain => 'test.com',
    :authentication => 'plain',:enable_starttls_auto=>"1", :testing_email => 'test@test.com'}
    assert_response :success
    assert_equal smtp_hash, ActionMailer::Base.smtp_settings
    assert_equal raise_delivery_errors_setting, ActionMailer::Base.raise_delivery_errors
  end

  test "get edit tag" do
    login_as(Factory(:admin))
    p = Factory(:person)
    model = Factory(:model)
    tag=Factory :tag,:value=>"twinkle",:source=>p.user,:annotatable=>model
    get :edit_tag,:id=>tag.value.id
    assert_response :success
  end

  test "non admin cannot get edit tag" do
    login_as(Factory(:person))
    p = Factory(:person)
    model = Factory(:model)
    tag=Factory :tag,:value=>"twinkle",:source=>p.user,:annotatable=>model
    get :edit_tag,:id=>tag.value.id
    assert_response :redirect
    refute_nil flash[:error]
  end


  test "job statistics stats" do
    login_as(:quentin)
    Delayed::Job.destroy_all
    dj = Delayed::Job.create(:run_at=>"2010 September 12",:locked_at=>"2010 September 13",:failed_at=>nil)
    dj.created_at = "2010 September 11"
    assert dj.save

    xml_http_request :get,:get_stats,{:id=>"job_queue"}
    assert_response :success

    assert_select "p",:text=>"Total delayed jobs waiting = 1"
    assert_select "tr" do
      assert_select "td",:text=>/11th Sep 2010 at/,:count=>1
      assert_select "td",:text=>/12th Sep 2010 at/,:count=>1
      assert_select "td",:text=>/13th Sep 2010 at/,:count=>1
      assert_select "td > span[class='none_text']",:text=>/No date defined/,:count=>1
    end

  end

  test "update home page settings" do
    login_as Factory(:admin).user
    assert_not_equal "This is the home description",Seek::Config.home_description
    post :update_home_settings,
         :home_description=>"This is the home description",
         :project_news_number_of_entries=>"3",
         :community_news_number_of_entries=>"7",
         :community_news_enabled=>"1",
         :project_news_enabled=>"1",
         :community_news_feed_urls=>"http://fish.com, http://goats.com",
         :project_news_feed_urls=>"http://carrot.com, http://soup.com"

    assert_equal "This is the home description",Seek::Config.home_description
    assert_equal "http://fish.com, http://goats.com",Seek::Config.community_news_feed_urls
    assert_equal "http://carrot.com, http://soup.com",Seek::Config.project_news_feed_urls
    assert_equal 7,Seek::Config.community_news_number_of_entries
    assert_equal 3,Seek::Config.project_news_number_of_entries
    assert Seek::Config.community_news_enabled
    assert Seek::Config.project_news_enabled
  end

  test "update doi locked, should be stored as int" do
    login_as(:quentin)
    post :update_features_enabled, :time_lock_doi_for => "6"
    assert_equal 6,Seek::Config.time_lock_doi_for
  end

  test "update_redirect_to for update_features_enabled" do
    login_as(:quentin)
    post :update_features_enabled, :time_lock_doi_for => '1', :port => '25'
    assert_redirected_to admin_path
    assert_nil flash[:error]

    post :update_features_enabled, :time_lock_doi_for => ''
    assert_redirected_to features_enabled_admin_path
    assert_not_nil flash[:error]
  end

  test "update_redirect_to for update_home_setting" do
    login_as(:quentin)
    post :update_home_settings, :project_news_number_of_entries => '10', :community_news_number_of_entries => '10'
    assert_redirected_to admin_path
    assert_nil flash[:error]

    post :update_home_settings, :project_news_number_of_entries => '10', :community_news_number_of_entries => ''
    assert_redirected_to home_settings_admin_path
    assert_not_nil flash[:error]
  end
end
