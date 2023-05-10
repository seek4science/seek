require 'test_helper'

class CookieConsentIntegrationTest < ActionDispatch::IntegrationTest

  test 'cookie consent banner shown' do
    with_config_value(:require_cookie_consent, true) do
      get root_path

      cookie_consent = CookieConsent.new(cookies)
      refute cookie_consent.given?
      assert cookie_consent.required?
      assert_select '#cookie-banner' do
        assert_select 'a[href=?]', cookies_consent_path(allow: 'necessary')
        assert_select 'a[href=?]', cookies_consent_path(allow: 'necessary,embedding')
        assert_select 'a[href=?]', cookies_consent_path(allow: all_options), count: 0
      end
    end
  end

  test 'cookie consent banner shown with tracking option if google analytics enabled' do
    with_config_value(:require_cookie_consent, true) do
      with_config_value(:google_analytics_enabled, true) do
        get root_path

        assert_select '#cookie-banner' do
          assert_select 'a[href=?]', cookies_consent_path(allow: 'necessary')
          assert_select 'a[href=?]', cookies_consent_path(allow: 'necessary,embedding')
          assert_select 'a[href=?]', cookies_consent_path(allow: all_options)
        end
      end
    end
  end

  test 'cookie consent banner shown with tracking option if matomo analytics enabled' do
    with_config_value(:require_cookie_consent, true) do
      with_config_value(:piwik_analytics_enabled, true) do
        get root_path

        assert_select '#cookie-banner' do
          assert_select 'a[href=?]', cookies_consent_path(allow: 'necessary')
          assert_select 'a[href=?]', cookies_consent_path(allow: 'necessary,embedding')
          assert_select 'a[href=?]', cookies_consent_path(allow: all_options)
        end
      end
    end
  end

  test 'cookie consent banner not shown if not required' do
    with_config_value(:require_cookie_consent, false) do
      get root_path

      cookie_consent = CookieConsent.new(cookies)
      assert cookie_consent.given?
      refute cookie_consent.required?
      assert_select '#cookie-banner', count: 0
    end
  end

  test 'cookie consent banner not shown if already consented' do
    with_config_value(:require_cookie_consent, true) do
      post cookies_consent_path, params: { allow: all_options }

      get root_path

      assert cookies.get_cookie('cookie_consent').expires > 5.years.from_now

      cookie_consent = CookieConsent.new(cookies)
      assert_equal ['tracking', 'embedding', 'necessary'], cookie_consent.options
      assert cookie_consent.given?
      assert_select '#cookie-banner', count: 0
    end
  end

  test 'google analytics code not present if only necessary cookies allowed' do
    with_config_value(:require_cookie_consent, true) do
      with_config_value(:google_analytics_enabled, true) do
        post cookies_consent_path, params: { allow: 'necessary' }

        get root_path

        assert_equal ['necessary'], CookieConsent.new(cookies).options
        assert_select '#ga-script', count: 0
      end
    end
  end

  test 'google analytics code not present if necessary and embedded cookies allowed' do
    with_config_value(:require_cookie_consent, true) do
      with_config_value(:google_analytics_enabled, true) do
        post cookies_consent_path, params: { allow: 'necessary,embedding' }

        get root_path

        assert_equal ['necessary', 'embedding'], CookieConsent.new(cookies).options
        assert_select '#ga-script', count: 0
      end
    end
  end

  test 'google analytics code present if only all cookies allowed' do
    with_config_value(:require_cookie_consent, true) do
      with_config_value(:google_analytics_enabled, true) do
        post cookies_consent_path, params: { allow: all_options }

        get root_path

        assert CookieConsent.new(cookies).allow_tracking?
        assert_select '#ga-script', count: 1
      end
    end
  end

  test 'google analytics code present if cookie consent not required' do
    with_config_value(:require_cookie_consent, false) do
      with_config_value(:google_analytics_enabled, true) do
        post cookies_consent_path, params: { allow: 'necessary' }

        get root_path

        cookie_consent = CookieConsent.new(cookies)
        assert_equal ['necessary'], cookie_consent.options
        assert cookie_consent.allow_tracking?
        assert_select '#ga-script', count: 1
      end
    end
  end

  test 'matomo analytics code not present if only necessary cookies allowed' do
    with_config_value(:require_cookie_consent, true) do
      with_config_value(:piwik_analytics_enabled, true) do
        post cookies_consent_path, params: { allow: 'necessary' }

        get root_path

        assert_equal ['necessary'], CookieConsent.new(cookies).options
        assert_select '#piwik-script', count: 0
      end
    end
  end

  test 'matomo analytics code not present if necessary and embedded cookies allowed' do
    with_config_value(:require_cookie_consent, true) do
      with_config_value(:piwik_analytics_enabled, true) do
        post cookies_consent_path, params: { allow: 'necessary,embedding' }

        get root_path

        assert_equal ['necessary', 'embedding'], CookieConsent.new(cookies).options
        assert_select '#piwik-script', count: 0
      end
    end
  end

  test 'matomo analytics code present if only all cookies allowed' do
    with_config_value(:require_cookie_consent, true) do
      with_config_value(:piwik_analytics_enabled, true) do
        post cookies_consent_path, params: { allow: all_options }

        get root_path

        assert CookieConsent.new(cookies).allow_tracking?
        assert_select '#piwik-script', count: 1
      end
    end
  end

  test 'matomo analytics code present if cookie consent not required' do
    with_config_value(:require_cookie_consent, false) do
      with_config_value(:piwik_analytics_enabled, true) do
        post cookies_consent_path, params: { allow: 'necessary' }

        get root_path

        cookie_consent = CookieConsent.new(cookies)
        assert_equal ['necessary'], cookie_consent.options
        assert cookie_consent.allow_tracking?
        assert_select '#piwik-script', count: 1
      end
    end
  end

  test 'can access and use cookie consent page as anonymous user' do
    with_config_value(:require_cookie_consent, true) do
      with_config_value(:google_analytics_enabled, true) do
        get cookies_consent_path

        #pp response.page.body

        assert_nil User.current_user
        assert_response :success
        assert_select '#cookie-consent-level', text: /No cookie consent/
        assert_select 'a[href=?]', cookies_consent_path(allow: 'necessary')
        assert_select 'a[href=?]', cookies_consent_path(allow: 'necessary,embedding')
        assert_select 'a[href=?]', cookies_consent_path(allow: all_options)

        post cookies_consent_path, params: { allow: 'necessary' }

        follow_redirect!
        assert_select '#flash-container .alert-danger', count: 0

        get cookies_consent_path

        assert_response :success
        assert_select '#cookie-consent-level', text: /No cookie consent/, count: 0
        assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics/, count: 0
        assert_select '#cookie-consent-level li', text: /Cookies necessary/

        post cookies_consent_path, params: { allow: all_options }

        get cookies_consent_path

        assert_response :success
        assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics/
        assert_select '#cookie-consent-level li', text: /Cookies necessary/
      end
    end
  end

  test 'can access cookie consent page as authenticated user' do
    @user = FactoryBot.create(:user, login: 'test')
    login_as(@user)

    with_config_value(:require_cookie_consent, true) do
      with_config_value(:google_analytics_enabled, true) do
        get cookies_consent_path

        assert_response :success
        assert_select '#cookie-consent-level', text: /No cookie consent/
        assert_select 'a[href=?]', cookies_consent_path(allow: 'necessary')
        assert_select 'a[href=?]', cookies_consent_path(allow: all_options)

        post cookies_consent_path, params: { allow: all_options }

        get cookies_consent_path
        assert_response :success

        assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics/
        assert_select '#cookie-consent-level li', text: /Cookies necessary/
      end
    end
  end

  test 'setting invalid cookie preferences shows an error' do
    with_config_value(:require_cookie_consent, true) do
      post cookies_consent_path, params: { allow: 'banana sandwich' }

      follow_redirect!

      assert_select '#error_flash', text: /Invalid cookie consent option provided/
    end
  end

  test 'revoke consent' do
    with_config_value(:require_cookie_consent, true) do
      with_config_value(:google_analytics_enabled, true) do
        post cookies_consent_path, params: { allow: 'necessary' }
        follow_redirect!
        assert_select '#error_flash .alert-danger', count: 0

        get cookies_consent_path
        assert_response :success

        assert_select '#cookie-consent-level', text: /No cookie consent/, count: 0
        assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics/, count: 0
        assert_select '#cookie-consent-level li', text: /Cookies necessary/
        assert_select '#cookie-banner', count: 0

        post cookies_consent_path, params: { allow: 'none' }
        follow_redirect!
        assert_select '#flash-container .alert-danger', count: 0

        get cookies_consent_path
        assert_response :success

        assert_select '#cookie-consent-level', text: /No cookie consent/
        assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics/, count: 0
        assert_select '#cookie-consent-level li', text: /Cookies necessary/, count: 0
        assert_select '#cookie-banner'
      end
    end
  end

  test 'remote presentation content should not be shown if not allowed' do
    with_config_value(:require_cookie_consent, true) do
      post cookies_consent_path, params: { allow: 'necessary' }

      presentation = FactoryBot.create :presentation, license: 'CC-BY-4.0', policy: FactoryBot.create(:public_policy)
      presentationv = FactoryBot.create :presentation_version_with_remote_content, presentation: presentation

      get presentation_path(presentation)
      assert_response :success

      assert_select 'iframe', count: 0
    end
  end

  test 'remote presentation content should be shown if only embedded allowed' do
    with_config_value(:require_cookie_consent, true) do
      post cookies_consent_path, params: { allow: 'necessary,embedding' }

      presentation = FactoryBot.create :presentation, license: 'CC-BY-4.0', policy: FactoryBot.create(:public_policy)
      presentationv = FactoryBot.create :presentation_version_with_remote_content, presentation: presentation

      get presentation_path(presentation)
      assert_response :success

      assert_select 'iframe', count: 1
    end
  end

  test 'remote presentation content should be shown if all allowed' do
    with_config_value(:require_cookie_consent, true) do
      post cookies_consent_path, params: { allow: all_options }

      presentation = FactoryBot.create :presentation, license: 'CC-BY-4.0', policy: FactoryBot.create(:public_policy)
      presentationv = FactoryBot.create :presentation_version_with_remote_content, presentation: presentation

      get presentation_path(presentation)
      assert_response :success

      assert_select 'iframe', count: 1
    end
  end

  test 'remote presentation content should be shown if consent not required' do
    with_config_value(:require_cookie_consent, false) do
      post cookies_consent_path, params: { allow: 'necessary' }

      presentation = FactoryBot.create :presentation, license: 'CC-BY-4.0', policy: FactoryBot.create(:public_policy)
      presentationv = FactoryBot.create :presentation_version_with_remote_content, presentation: presentation

      get presentation_path(presentation)
      assert_response :success

      assert_select 'iframe', count: 1
    end
  end

  test 'local presentation content should be shown even if not allowed' do
    with_config_value(:require_cookie_consent, true) do
      post cookies_consent_path, params: { allow: 'necessary' }

      presentation = FactoryBot.create :presentation, license: 'CC-BY-4.0', policy: FactoryBot.create(:public_policy)
      presentationv = FactoryBot.create :presentation_version_with_blob, presentation: presentation

      get presentation_path(presentation)
      assert_response :success

      assert_select 'iframe', count: 1
    end
  end

  test 'should show workflow embedded youtube video if consent not required' do
    with_config_value(:require_cookie_consent, false) do
      post cookies_consent_path, params: { allow: 'necessary' }

      @user = FactoryBot.create(:user, login: 'test')
      login_as(@user)

      workflow = FactoryBot.create(:local_git_workflow, contributor: @user.person)
      version = workflow.latest_git_version

      version.add_remote_file('video.html', 'https://youtu.be/1234abcd')
      disable_authorization_checks { version.save! }

      get workflow_git_blob_path(workflow.id, version.version, 'video.html')

      assert_select 'iframe[src=?]', 'https://www.youtube-nocookie.com/embed/1234abcd'
    end
  end

  test 'should show workflow embedded youtube video if embedded consent given' do
    with_config_value(:require_cookie_consent, true) do
      post cookies_consent_path, params: { allow: 'necessary,embedding' }

      @user = FactoryBot.create(:user, login: 'test')
      login_as(@user)

      workflow = FactoryBot.create(:local_git_workflow, contributor: @user.person)
      version = workflow.latest_git_version

      version.add_remote_file('video.html', 'https://youtu.be/1234abcd')
      disable_authorization_checks { version.save! }

      get workflow_git_blob_path(workflow.id, version.version, 'video.html')

      assert_select 'iframe[src=?]', 'https://www.youtube-nocookie.com/embed/1234abcd'
    end
  end

  test 'should show workflow embedded youtube video if consent given for all ' do
    with_config_value(:require_cookie_consent, false) do
      post cookies_consent_path, params: { allow: all_options }

      @user = FactoryBot.create(:user, login: 'test')
      login_as(@user)

      workflow = FactoryBot.create(:local_git_workflow, contributor: @user.person)
      version = workflow.latest_git_version

      version.add_remote_file('video.html', 'https://youtu.be/1234abcd')
      disable_authorization_checks { version.save! }

      get workflow_git_blob_path(workflow.id, version.version, 'video.html')

      assert_select 'iframe[src=?]', 'https://www.youtube-nocookie.com/embed/1234abcd'
    end
  end

  test 'should not show workflow embedded youtube video if consent given for only for necessary ' do
    with_config_value(:require_cookie_consent, false) do
      post cookies_consent_path, params: { allow: 'necessary' }

      @user = FactoryBot.create(:user, login: 'test')
      login_as(@user)

      workflow = FactoryBot.create(:local_git_workflow, contributor: @user.person)
      version = workflow.latest_git_version

      version.add_remote_file('video.html', 'https://youtu.be/1234abcd')
      disable_authorization_checks { version.save! }

      get workflow_git_blob_path(workflow.id, version.version, 'video.html')

      assert_select 'iframe[src=?]', 'https://www.youtube-nocookie.com/embed/1234abcd'
    end
  end

  test 'analytics consent text changes depending on which analytics enabled' do
    with_config_value(:require_cookie_consent, true) do
      post cookies_consent_path, params: { allow: all_options }

      with_config_value(:google_analytics_enabled, true) do
        with_config_value(:piwik_analytics_enabled, true) do
          get cookies_consent_path

          assert_select '#content p', text: /Additionally, we make use of Google Analytics and Matomo to/
          assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics and Matomo, to/
        end
        with_config_value(:piwik_analytics_enabled, false) do
          get cookies_consent_path

          assert_select '#content p', text: /Additionally, we make use of Google Analytics to/
          assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics, to/
        end
      end
      with_config_value(:google_analytics_enabled, false) do
        with_config_value(:piwik_analytics_enabled, true) do
          get cookies_consent_path

          assert_select '#content p', text: /Additionally, we make use of Matomo to/
          assert_select '#cookie-consent-level li', text: /Cookies required for Matomo, to/
        end
        with_config_value(:piwik_analytics_enabled, false) do
          get cookies_consent_path

          assert_select '#content p', text: /Additionally, we make use of/, count: 0
          assert_select '#cookie-consent-level li', text: /Cookies required for/, count: 0
        end
      end
    end
  end

  private

  def all_options
    CookieConsent::OPTIONS.join(',')
  end

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end
