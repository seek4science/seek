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
      post :update_features_enabled, params: { events_enabled: '1' }
      assert Seek::Config.events_enabled
    end
  end

  test 'update SMTP settings' do
    with_config_value(:email_enabled, false) do
      with_config_value(:smtp, { address: '255.255.255.255', 'address' => '0.0.0.0' }) do
        assert_equal 'Hash', Seek::Config.smtp.class.name

        post :update_features_enabled, params: { email_enabled: '1', address: '127.0.0.1', port: '25', domain: 'email.example.com', authentication: 'plain', smtp_user_name: '', smtp_password: '', enable_starttls_auto: '1' }

        assert_equal 'ActiveSupport::HashWithIndifferentAccess', Seek::Config.smtp.class.name
        assert Seek::Config.email_enabled

        mailer_settings = ActionMailer::Base.smtp_settings
        assert_equal '127.0.0.1', mailer_settings[:address]
        assert_equal '25', mailer_settings[:port]
        assert_equal 'email.example.com', mailer_settings[:domain]
        assert_equal 'plain', mailer_settings[:authentication]
        assert_nil mailer_settings[:user_name]
        assert_nil mailer_settings[:password]
        assert mailer_settings[:enable_starttls_auto]
      end
    end
  end

  test 'should read SMTP setting as a HashWithIndifferentAccess' do
    with_config_value(:smtp, { address: '255.255.255.255', 'domain' => 'email.example.com' }) do
      assert_equal 'Hash', Seek::Config.smtp.class.name

      get :features_enabled

      assert_response :success
      assert_select '#address[value=?]', '255.255.255.255'
      assert_select '#domain[value=?]', 'email.example.com'
    end
  end

  test 'update visible tags and threshold' do
    Seek::Config.max_visible_tags = 2
    Seek::Config.tag_threshold = 2
    post :update_home_settings, params: { tag_threshold: '8', max_visible_tags: '9' }
    assert_equal 8, Seek::Config.tag_threshold
    assert_equal 9, Seek::Config.max_visible_tags
  end

  test 'update default default_associated_projects_access_type permissions' do
    Seek::Config.default_associated_projects_access_type = 0
    assert_equal 0, Seek::Config.default_associated_projects_access_type
    post :update_settings, params: { default_associated_projects_access_type: '2' }
    assert_equal 2, Seek::Config.default_associated_projects_access_type
  end

  test 'update default default_all_visitors_access_type permissions' do
    Seek::Config.default_all_visitors_access_type = 0
    assert_equal 0, Seek::Config.default_all_visitors_access_type
    post :update_settings, params: { default_all_visitors_access_type: '2' }
    assert_equal 2, Seek::Config.default_all_visitors_access_type
  end

  test 'update permissions popup' do
    Seek::Config.permissions_popup = Seek::Config::PERMISSION_POPUP_ALWAYS
    assert_equal Seek::Config::PERMISSION_POPUP_ALWAYS, Seek::Config.permissions_popup
    post :update_settings, params: { permissions_popup: "#{Seek::Config::PERMISSION_POPUP_NEVER}" }
    assert_equal Seek::Config::PERMISSION_POPUP_NEVER, Seek::Config.permissions_popup
  end

  test 'invalid email address' do
    post :update_settings, params: { pubmed_api_email: 'quentin', crossref_api_email: 'quentin@example.com' }
    assert_not_nil flash[:error]
  end

  test 'should input integer' do
    post :update_home_settings, params: { tag_threshold: '', max_visible_tags: '20' }
    assert_not_nil flash[:error]
  end

  test 'should input positive integer' do
    post :update_home_settings, params: { tag_threshold: '1', max_visible_tags: '0' }
    assert_not_nil flash[:error]
  end

  test 'update admins' do
    quentin = people(:quentin_person)
    aaron = people(:aaron_person)

    assert quentin.is_admin?
    assert !aaron.is_admin?

    post :update_admins, params: { admins: "#{aaron.id}" }

    quentin.reload
    aaron.reload

    assert !quentin.is_admin?
    assert aaron.is_admin?
    assert aaron.is_admin?
  end

  test 'get project content stats' do
    get :get_stats, xhr: true, params: { page: 'content_stats' }
    assert_response :success
  end

  test 'get auth consistency stats' do
    get :get_stats, xhr: true, params: { page: 'auth_consistency' }
    assert_response :success
  end

  test 'The configuration should stay the same after test_email_configuration' do
    smtp_hash = ActionMailer::Base.smtp_settings
    raise_delivery_errors_setting = ActionMailer::Base.raise_delivery_errors
    post :test_email_configuration, xhr: true, params: {
        address: '127.0.0.1', port: '25', domain: 'test.com', authentication: 'plain',
        enable_starttls_auto: '1', testing_email: 'test@test.com' }
    assert_response :success
    assert_equal smtp_hash, ActionMailer::Base.smtp_settings
    assert_equal raise_delivery_errors_setting, ActionMailer::Base.raise_delivery_errors
  end

  test 'get edit tag' do
    p = Factory(:person)
    model = Factory(:model)
    tag = Factory :tag, value: 'twinkle', source: p.user, annotatable: model
    get :edit_tag, params: { id: tag.value.id }
    assert_response :success
  end

  test 'non admin cannot get edit tag' do
    login_as(Factory(:user))
    p = Factory(:person)
    model = Factory(:model)
    tag = Factory :tag, value: 'twinkle', source: p.user, annotatable: model
    get :edit_tag, params: { id: tag.value.id }
    assert_response :redirect
    refute_nil flash[:error]
  end

  test 'job statistics stats' do
    Delayed::Job.destroy_all
    dj = Delayed::Job.create(run_at: '2010 September 12', locked_at: '2010 September 13', failed_at: nil)
    dj.created_at = '2010 September 11'
    assert dj.save

    get :get_stats, xhr: true, params: { page: 'job_queue' }
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
    get :get_stats, xhr: true, params: { page: 'storage_usage_stats' }
    assert_response :success
  end

  test 'update home page settings' do
    assert_not_equal 'This is the home description', Seek::Config.home_description
    post :update_home_settings, params: { home_description: 'This is the home description', news_number_of_entries: '3', news_enabled: '1', news_feed_urls: 'http://fish.com, http://goats.com' }

    assert_equal 'This is the home description', Seek::Config.home_description
    assert_equal 'http://fish.com, http://goats.com', Seek::Config.news_feed_urls
    assert_equal 3, Seek::Config.news_number_of_entries
    assert Seek::Config.news_enabled
  end

  test 'update doi locked, should be stored as int' do
    post :update_features_enabled, params: { time_lock_doi_for: '6' }
    assert_equal 6, Seek::Config.time_lock_doi_for
  end

  test 'update_redirect_to for update_features_enabled' do
    post :update_features_enabled, params: { time_lock_doi_for: '1', port: '25' }
    assert_redirected_to admin_path
    assert_nil flash[:error]

    post :update_features_enabled, params: { time_lock_doi_for: '' }
    assert_redirected_to features_enabled_admin_path
    assert_not_nil flash[:error]
  end

  test 'update_redirect_to for update_home_setting' do
    post :update_home_settings, params: { news_number_of_entries: '10', tag_threshold: '1', max_visible_tags: '20' }
    assert_redirected_to admin_path
    assert_nil flash[:error]

    post :update_home_settings, params: { news_number_of_entries: '', tag_threshold: '1', max_visible_tags: '20' }
    assert_redirected_to home_settings_admin_path
    assert_not_nil flash[:error]
  end

  test 'openbis enabled' do
    with_config_value(:openbis_enabled, false) do
      post :update_features_enabled, params: { openbis_enabled: '1' }
      assert Seek::Config.openbis_enabled
    end
    with_config_value(:openbis_enabled, true) do
      post :update_features_enabled, params: { openbis_enabled: '0' }
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

    get :get_stats, xhr: true, params: { page: 'snapshot_and_doi_stats' }
    assert_response :success
  end

  test 'clear failed jobs' do
    Delayed::Job.destroy_all
    job = Delayed::Job.create!
    job.update_column(:failed_at,Time.now)
    Delayed::Job.create!
    assert_equal 2,Delayed::Job.count
    assert_difference('Delayed::Job.count',-1) do
      post :clear_failed_jobs, format: 'json'
    end

    assert_equal 1,Delayed::Job.count
    assert_equal 0,Delayed::Job.where('failed_at IS NOT NULL').count
  end

  test 'admin required to clear failed jobs' do
    logout
    person = Factory(:person)

    Delayed::Job.destroy_all
    job = Delayed::Job.create!
    job.update_column(:failed_at,Time.now)
    Delayed::Job.create!
    assert_equal 2,Delayed::Job.count

    assert_no_difference('Delayed::Job.count') do
      post :clear_failed_jobs, format: 'json'
    end

    login_as(person)

    assert_no_difference('Delayed::Job.count') do
      post :clear_failed_jobs, format: 'json'
    end

    assert_equal 2,Delayed::Job.count
    assert_equal 1,Delayed::Job.where('failed_at IS NOT NULL').count
  end

  test 'update branding' do
    assert_nil Seek::Config.header_image_avatar_id
    settings = {project_name: 'project name', project_type: 'project type', project_description: 'project description', project_keywords: 'project,    keywords, ',
                project_link: 'http://project-link.com',application_name: 'app name',
                dm_project_name: 'dm project name', dm_project_link: 'http://dm-project-link.com',
                header_image_link: 'http://header-link.com/image.jpg', header_image_title: 'header image title',
                copyright_addendum_content: 'copyright content', imprint_description: 'imprint description',
                terms_page: 'terms page', privacy_page: 'privacy page', about_page: 'about page',
                header_image_file: fixture_file_upload('files/file_picture.png', 'image/png') }

    assert_difference('Avatar.count', 1) do
      post :update_rebrand, params: settings
    end
    assert_redirected_to admin_path

    assert_equal 'project name', Seek::Config.project_name
    assert_equal 'project type', Seek::Config.project_type
    assert_equal 'project description', Seek::Config.project_description
    assert_equal 'project, keywords', Seek::Config.project_keywords
    assert_equal 'http://project-link.com', Seek::Config.project_link
    assert_equal 'app name', Seek::Config.application_name
    assert_equal 'dm project name', Seek::Config.dm_project_name
    assert_equal 'http://dm-project-link.com', Seek::Config.dm_project_link
    assert_equal 'http://header-link.com/image.jpg', Seek::Config.header_image_link
    assert_equal 'header image title', Seek::Config.header_image_title
    assert_equal 'copyright content', Seek::Config.copyright_addendum_content
    assert_equal 'imprint description', Seek::Config.imprint_description
    assert_equal 'terms page', Seek::Config.terms_page
    assert_equal 'privacy page', Seek::Config.privacy_page
    assert_equal 'about page', Seek::Config.about_page
    assert Seek::Config.header_image_avatar_id > 0
  end

  test 'update pagination' do
    post :update_pagination, params: {
        results_per_page_default: 9,
        search_results_limit: '45',
        related_items_limit: 123,
        results_per_page: { people: 6, 'models' => '300', publications: '', sops: nil },
        sorting: { people: 'created_at_asc', models: :created_at_desc,
                   data_files: 'published_at_desc', sops: 'bananabread' } }

    assert_redirected_to admin_path

    assert_equal 9, Seek::Config.results_per_page_default
    assert_equal 6, Seek::Config.results_per_page_for('people')
    assert_equal 300, Seek::Config.results_per_page_for('models')
    assert_nil Seek::Config.results_per_page_for('publications')
    assert_nil Seek::Config.results_per_page_for('sops')
    assert_nil Seek::Config.results_per_page_for('data_files')

    assert_equal :created_at_asc, Seek::Config.sorting_for('people')
    assert_equal :created_at_desc, Seek::Config.sorting_for('models')
    assert_nil Seek::Config.results_per_page_for('publications')
    assert_nil Seek::Config.results_per_page_for('sops')
    assert_nil Seek::Config.results_per_page_for('data_files'), "Shouldn't set to a value that is not a valid sorting option."

    assert_equal 45, Seek::Config.search_results_limit
    assert_equal 123, Seek::Config.related_items_limit
  end

  test 'update LDAP settings' do
    with_config_value(:omniauth_ldap_enabled, false) do
      with_config_value(:omniauth_ldap_config, { }) do
        assert_equal 'Hash', Seek::Config.omniauth_ldap_config.class.name

        post :update_features_enabled, params: {
            omniauth_ldap_enabled: '1',
            omniauth_ldap_host: '127.0.0.1',
            omniauth_ldap_port: '999',
            omniauth_ldap_base: 'DC=cool,DC=com',
            omniauth_ldap_method: 'tls',
            omniauth_ldap_uid: 'uzername',
            omniauth_ldap_bind_dn: 'DC=secret,DC=com',
            omniauth_ldap_password: '123456'
        }

        assert_equal 'ActiveSupport::HashWithIndifferentAccess', Seek::Config.omniauth_ldap_config.class.name
        assert Seek::Config.omniauth_ldap_enabled
        assert_equal '127.0.0.1', Seek::Config.omniauth_ldap_config['host']
        assert_equal '127.0.0.1', Seek::Config.omniauth_ldap_settings('host')
        assert_equal 999, Seek::Config.omniauth_ldap_config['port']
        assert_equal 999, Seek::Config.omniauth_ldap_settings('port')
        assert_equal 'DC=cool,DC=com', Seek::Config.omniauth_ldap_config['base']
        assert_equal 'DC=cool,DC=com', Seek::Config.omniauth_ldap_settings('base')
        assert_equal :tls, Seek::Config.omniauth_ldap_config['method']
        assert_equal :tls, Seek::Config.omniauth_ldap_settings('method')
        assert_equal 'uzername', Seek::Config.omniauth_ldap_config['uid']
        assert_equal 'uzername', Seek::Config.omniauth_ldap_settings('uid')
        assert_equal 'DC=secret,DC=com', Seek::Config.omniauth_ldap_config['bind_dn']
        assert_equal 'DC=secret,DC=com', Seek::Config.omniauth_ldap_settings('bind_dn')
        assert_equal '123456', Seek::Config.omniauth_ldap_config['password']
        assert_equal '123456', Seek::Config.omniauth_ldap_settings('password')
      end
    end
  end

  test 'email settings preserved if not sent' do

    Seek::Config.set_smtp_settings('address', 'smtp.address.org')
    Seek::Config.set_smtp_settings('port', 1)
    Seek::Config.set_smtp_settings('domain', 'the-domain')
    Seek::Config.set_smtp_settings('authentication', 'auth')
    Seek::Config.set_smtp_settings('user_name', 'fred')
    Seek::Config.set_smtp_settings('password', 'blogs')
    Seek::Config.set_smtp_settings('enable_starttls_auto', true)

    with_config_value(:support_email_address, 'support@email.com') do
      with_config_value(:noreply_sender, 'no-reply@sender.com') do
        with_config_value(:exception_notification_recipients, 'errors@fred.org, errors@john.org') do
          with_config_value(:exception_notification_enabled, true) do
            post :update_features_enabled, params: {}

            assert_equal 'smtp.address.org', Seek::Config.smtp_settings('address')
            assert_equal 1, Seek::Config.smtp_settings('port')
            assert_equal 'the-domain', Seek::Config.smtp_settings('domain')
            assert_equal 'auth', Seek::Config.smtp_settings('authentication')
            assert_equal 'fred', Seek::Config.smtp_settings('user_name')
            assert_equal 'blogs', Seek::Config.smtp_settings('password')
            assert_equal true, Seek::Config.smtp_settings('enable_starttls_auto')

            assert_equal 'support@email.com', Seek::Config.support_email_address
            assert_equal 'no-reply@sender.com', Seek::Config.noreply_sender
            assert_equal 'errors@fred.org, errors@john.org', Seek::Config.exception_notification_recipients
            assert_equal true, Seek::Config.exception_notification_enabled
          end
        end
      end
    end
  end

  test 'recommended data licenses' do
    Seek::Config.recommended_data_licenses = []
    new_value = ['CC-BY-4.0']
    post :update_settings, params: {recommended_data_licenses: new_value}
    assert_equal new_value, Seek::Config.recommended_data_licenses
    new_value = []
    post :update_settings, params: {recommended_data_licenses: new_value}
    assert_equal nil, Seek::Config.recommended_data_licenses
  end

  test 'recommended software licenses' do
    Seek::Config.recommended_software_licenses = []
    new_value = ['BitTorrent-1.1']
    post :update_settings, params: {recommended_software_licenses: new_value}
    assert_equal new_value, Seek::Config.recommended_software_licenses
    new_value = []
    post :update_settings, params: {recommended_software_licenses: new_value}
    assert_equal nil, Seek::Config.recommended_software_licenses
  end

  test 'publication fulltext enabled' do
    with_config_value(:allow_publications_fulltext, false) do
      post :update_settings, params: { allow_publications_fulltext: '1' }
      assert_equal true, Seek::Config.allow_publications_fulltext
    end
    with_config_value(:allow_publications_fulltext, true) do
      post :update_settings, params: { allow_publications_fulltext: '0' }
      assert_equal false, Seek::Config.allow_publications_fulltext
    end
  end
end
