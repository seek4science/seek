require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(Factory(:admin))
  end

  test 'should show rebrand' do
    get :rebrand
    assert_response :success
  end

  test 'non admin cannot restart the server' do
    login_as(Factory(:user))
    post :restart_server
    assert_not_nil flash[:error]
  end

  test 'admin can restart the server' do
    post :restart_server
    assert_nil flash[:error]
  end

  test 'get registration form' do
    get :registration_form
    assert_response :success
  end

  test 'non admin cannot restart the delayed job' do
    login_as(Factory(:user))
    post :restart_delayed_job
    assert_not_nil flash[:error]
  end

  test 'admin can restart the delayed job' do
    post :restart_delayed_job
    assert_nil flash[:error]
  end

  test 'none admin not get registration form' do
    login_as Factory(:user)
    get :registration_form
    assert !User.current_user.person.is_admin?
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test 'should show features enabled' do
    get :features_enabled
    assert_response :success
  end

  test 'should show pagination' do
    get :pagination
    assert_response :success
  end

  test 'should show settings' do
    get :settings
    assert_response :success
  end

  test 'visible to admin' do
    get :index
    assert_response :success
    assert_nil flash[:error]
  end

  test 'invisible to non admin' do
    login_as(Factory(:user))
    get :index
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test 'string to boolean' do
    with_config_value(:events_enabled, false) do
      post :update_features_enabled, events_enabled: '1'
      assert Seek::Config.events_enabled
    end
  end

  test 'update visible tags and threshold' do
    Seek::Config.max_visible_tags = 2
    Seek::Config.tag_threshold = 2
    post :update_home_settings, tag_threshold: '8', max_visible_tags: '9'
    assert_equal 8, Seek::Config.tag_threshold
    assert_equal 9, Seek::Config.max_visible_tags
  end

  test 'update default default_associated_projects_access_type permissions' do
    Seek::Config.default_associated_projects_access_type = 0
    assert_equal 0, Seek::Config.default_associated_projects_access_type
    post :update_settings, default_associated_projects_access_type: '2'
    assert_equal 2, Seek::Config.default_associated_projects_access_type
  end

  test 'update default default_all_visitors_access_type permissions' do
    Seek::Config.default_all_visitors_access_type = 0
    assert_equal 0, Seek::Config.default_all_visitors_access_type
    post :update_settings, default_all_visitors_access_type: '2'
    assert_equal 2, Seek::Config.default_all_visitors_access_type
  end

  test 'update permissions popup' do
    Seek::Config.permissions_popup = Seek::Config::PERMISSION_POPUP_ALWAYS
    assert_equal Seek::Config::PERMISSION_POPUP_ALWAYS, Seek::Config.permissions_popup
    post :update_settings, permissions_popup: "#{Seek::Config::PERMISSION_POPUP_NEVER}"
    assert_equal Seek::Config::PERMISSION_POPUP_NEVER, Seek::Config.permissions_popup
  end

  test 'invalid email address' do
    post :update_settings, pubmed_api_email: 'quentin', crossref_api_email: 'quentin@example.com'
    assert_not_nil flash[:error]
  end

  test 'should input integer' do
    post :update_home_settings, tag_threshold: '', max_visible_tags: '20'
    assert_not_nil flash[:error]
  end

  test 'should input positive integer' do
    post :update_home_settings, tag_threshold: '1', max_visible_tags: '0'
    assert_not_nil flash[:error]
  end

  test 'update admins' do
    quentin = people(:quentin_person)
    aaron = people(:aaron_person)

    assert quentin.is_admin?
    assert !aaron.is_admin?

    post :update_admins, admins: "#{aaron.id}"

    quentin.reload
    aaron.reload

    assert !quentin.is_admin?
    assert aaron.is_admin?
    assert aaron.is_admin?
  end

  test 'get project content stats' do
    xml_http_request :get, :get_stats, page:  'content_stats'
    assert_response :success
  end

  test 'The configuration should stay the same after test_email_configuration' do
    smtp_hash = ActionMailer::Base.smtp_settings
    raise_delivery_errors_setting = ActionMailer::Base.raise_delivery_errors
    xml_http_request :post, :test_email_configuration, address: '127.0.0.1', port: '25', domain: 'test.com',
                                                       authentication: 'plain', enable_starttls_auto: '1', testing_email: 'test@test.com'
    assert_response :success
    assert_equal smtp_hash, ActionMailer::Base.smtp_settings
    assert_equal raise_delivery_errors_setting, ActionMailer::Base.raise_delivery_errors
  end

  test 'get edit tag' do
    p = Factory(:person)
    model = Factory(:model)
    tag = Factory :tag, value: 'twinkle', source: p.user, annotatable: model
    get :edit_tag, id: tag.value.id
    assert_response :success
  end

  test 'non admin cannot get edit tag' do
    login_as(Factory(:user))
    p = Factory(:person)
    model = Factory(:model)
    tag = Factory :tag, value: 'twinkle', source: p.user, annotatable: model
    get :edit_tag, id: tag.value.id
    assert_response :redirect
    refute_nil flash[:error]
  end

  test 'job statistics stats' do
    Delayed::Job.destroy_all
    dj = Delayed::Job.create(run_at: '2010 September 12', locked_at: '2010 September 13', failed_at: nil)
    dj.created_at = '2010 September 11'
    assert dj.save

    xml_http_request :get, :get_stats, page:  'job_queue'
    assert_response :success

    assert_select 'p', text: 'Total delayed jobs waiting = 1'
    assert_select 'tr' do
      assert_select 'td', text: /11th Sep 2010 at/, count: 1
      assert_select 'td', text: /12th Sep 2010 at/, count: 1
      assert_select 'td', text: /13th Sep 2010 at/, count: 1
      assert_select "td > span[class='none_text']", text: /No date defined/, count: 1
    end
  end

  test 'storage usage stats' do
    Factory(:rightfield_datafile)
    Factory(:rightfield_annotated_datafile)
    xml_http_request :get, :get_stats, page:  'storage_usage_stats'
    assert_response :success
  end

  test 'update home page settings' do
    assert_not_equal 'This is the home description', Seek::Config.home_description
    post :update_home_settings,
         home_description: 'This is the home description',
         news_number_of_entries: '3',
         news_enabled: '1',
         news_feed_urls: 'http://fish.com, http://goats.com'

    assert_equal 'This is the home description', Seek::Config.home_description
    assert_equal 'http://fish.com, http://goats.com', Seek::Config.news_feed_urls
    assert_equal 3, Seek::Config.news_number_of_entries
    assert Seek::Config.news_enabled
  end

  test 'update doi locked, should be stored as int' do
    post :update_features_enabled, time_lock_doi_for: '6'
    assert_equal 6, Seek::Config.time_lock_doi_for
  end

  test 'update_redirect_to for update_features_enabled' do
    post :update_features_enabled, time_lock_doi_for: '1', port: '25'
    assert_redirected_to admin_path
    assert_nil flash[:error]

    post :update_features_enabled, time_lock_doi_for: ''
    assert_redirected_to features_enabled_admin_path
    assert_not_nil flash[:error]
  end

  test 'update_redirect_to for update_home_setting' do
    post :update_home_settings, news_number_of_entries: '10', tag_threshold: '1', max_visible_tags: '20'
    assert_redirected_to admin_path
    assert_nil flash[:error]

    post :update_home_settings, news_number_of_entries: '', tag_threshold: '1', max_visible_tags: '20'
    assert_redirected_to home_settings_admin_path
    assert_not_nil flash[:error]
  end

  test 'openbis enabled' do
    with_config_value(:openbis_enabled, false) do
      post :update_features_enabled, openbis_enabled: '1'
      assert Seek::Config.openbis_enabled
    end
    with_config_value(:openbis_enabled, true) do
      post :update_features_enabled, openbis_enabled: '0'
      refute Seek::Config.openbis_enabled
    end
  end

  test 'snapshot and doi stats' do
    investigation = Factory(:investigation, title: 'i1', description: 'not blank',
                            policy: Factory(:downloadable_public_policy))
    snapshot = investigation.create_snapshot
    snapshot.update_column(:doi, '10.5072/testytest')
    AssetDoiLog.create(asset_type: 'investigation',
                       asset_id: investigation.id,
                       action: AssetDoiLog::MINT)

    xml_http_request :get, :get_stats, page:  'snapshot_and_doi_stats'
    assert_response :success
  end
end
