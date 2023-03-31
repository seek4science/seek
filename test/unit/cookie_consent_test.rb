require 'test_helper'

class CookieConsentTest < ActiveSupport::TestCase

  test 'permanent cookies' do
    store = Rack::Test::CookieJar.new
    refute store.permanent_called
    cookie_consent = CookieConsent.new(store)
    cookie_consent.options = 'embedding,tracking,necessary'
    assert store.permanent_called
  end

  test 'should check if consent required?' do
    with_config_value(:require_cookie_consent, false) do
      cookie_consent = CookieConsent.new(Rack::Test::CookieJar.new)
      refute cookie_consent.required?
      assert cookie_consent.given?
      assert cookie_consent.allow_embedding?
      assert cookie_consent.allow_tracking?
      assert cookie_consent.allow_necessary?
    end

    with_config_value(:require_cookie_consent, true) do
      cookie_consent = CookieConsent.new(Rack::Test::CookieJar.new)
      assert cookie_consent.required?
      refute cookie_consent.given?
      refute cookie_consent.allow_embedding?
      refute cookie_consent.allow_tracking?
      refute cookie_consent.allow_necessary?

      cookie_consent = CookieConsent.new(Rack::Test::CookieJar.new)
      cookie_consent.options = 'embedding,tracking,necessary'
      assert cookie_consent.required?
      assert cookie_consent.given?
      assert cookie_consent.allow_embedding?
      assert cookie_consent.allow_tracking?
      assert cookie_consent.allow_necessary?

      cookie_consent = CookieConsent.new(Rack::Test::CookieJar.new)
      cookie_consent.options = 'embedding'
      assert cookie_consent.required?
      assert cookie_consent.given?
      assert cookie_consent.allow_embedding?
      refute cookie_consent.allow_tracking?
      refute cookie_consent.allow_necessary?

      cookie_consent = CookieConsent.new(Rack::Test::CookieJar.new)
      cookie_consent.options = 'banana,necessary'
      assert cookie_consent.required?
      assert cookie_consent.given?
      refute cookie_consent.allow_embedding?
      refute cookie_consent.allow_tracking?
      assert cookie_consent.allow_necessary?

      cookie_consent = CookieConsent.new(Rack::Test::CookieJar.new)
      cookie_consent.options = 'banana,golf'
      assert cookie_consent.required?
      refute cookie_consent.given?
      refute cookie_consent.allow_embedding?
      refute cookie_consent.allow_tracking?
      refute cookie_consent.allow_necessary?
    end
  end

  test 'should get and set consent level, and validate level' do
    with_config_value(:require_cookie_consent, true) do
      cookie_consent = CookieConsent.new(Rack::Test::CookieJar.new)

      assert_empty cookie_consent.options
      refute cookie_consent.given?

      cookie_consent.options = 'necessary'
      assert_equal ['necessary'], cookie_consent.options
      assert cookie_consent.given?

      cookie_consent.options = 'necessary,tracking'
      assert_equal ['necessary', 'tracking'], cookie_consent.options
      assert cookie_consent.given?

      cookie_consent.options = 'necessary,tracking,embedding'
      assert_equal ['necessary', 'tracking', 'embedding'], cookie_consent.options
      assert cookie_consent.given?

      cookie_consent.options = 'necessary,tracking,embedding,something else'
      assert_equal ['necessary', 'tracking', 'embedding'], cookie_consent.options
      assert cookie_consent.given?

      cookie_consent.options = 'banana'
      assert_equal [], cookie_consent.options
      refute cookie_consent.given?
    end
  end
end
