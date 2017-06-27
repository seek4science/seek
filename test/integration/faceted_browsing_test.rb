require 'test_helper'

class FacetedBrowsingTest < ActionDispatch::IntegrationTest
  ASSETS_WITH_FACET = Seek::Config.facet_enable_for_pages.keys

  def setup
    User.current_user = Factory(:user, login: 'test')
    post '/session', login: 'test', password: 'blah'
  end

  test 'turn off the faceted browsing' do
    with_config_value :faceted_browsing_enabled, false do
      example_items
      ASSETS_WITH_FACET.each do |type_name|
        get "/#{type_name}", user_enable_facet: 'true'
        assert_select "table[id='exhibit']", count: 0
        assert_select 'div.alphabetical_pagination'
      end
    end
  end

  test 'turn on the faceted browsing' do
    with_config_value :faceted_browsing_enabled, true do
      example_items
      ASSETS_WITH_FACET.each do |type_name|
        with_config_value :facet_enable_for_pages, type_name => true do
          get "/#{type_name}", user_enable_facet: 'true'
          assert_select "div[id='exhibit']"
          assert_select 'div.alphabetical_pagination', count: 0
        end
      end
    end
  end

  test 'partly turn on the faceted browsing' do
    with_config_value :faceted_browsing_enabled, true do
      example_items
      facet_enabled_pages = {}
      facet_disabled_pages = {}
      Seek::Config.facet_enable_for_pages.each do |key, value|
        if value == true
          facet_enabled_pages[key] = value
        else
          facet_disabled_pages[key] = value
        end
      end

      assert !facet_enabled_pages.blank?
      assert !facet_disabled_pages.blank?

      facet_enabled_pages.keys.each do |type_name|
        get "/#{type_name}", user_enable_facet: 'true'
        assert_select "div[id='exhibit']"
        assert_select 'div.alphabetical_pagination', count: 0
      end

      facet_disabled_pages.keys.each do |type_name|
        get "/#{type_name}", user_enable_facet: 'true'
        assert_select "div[id='exhibit']", count: 0
        assert_select 'div.alphabetical_pagination'
      end
    end
  end

  test 'user_enable_facet' do
    with_config_value :faceted_browsing_enabled, true do
      example_items
      ASSETS_WITH_FACET.each do |type_name|
        with_config_value :facet_enable_for_pages, type_name => true do
          get "/#{type_name}", user_enable_facet: 'true'
          assert_select "div[id='exhibit']"
          assert_select 'div.alphabetical_pagination', count: 0

          get "/#{type_name}"
          assert_select "div[id='exhibit']", count: 0
          assert_select 'div.alphabetical_pagination'
        end
      end
    end
  end

  test 'toogle -advance filter- button and -stop filtering- button' do
    with_config_value :faceted_browsing_enabled, true do
      example_items
      ASSETS_WITH_FACET.each do |type_name|
        with_config_value :facet_enable_for_pages, type_name => true do
          get "/#{type_name}"
          assert_select "a[style='']", text: /Advanced filtering/
          assert_select "a[style='display: none']", text: /Stop filtering/

          get "/#{type_name}", user_enable_facet: 'true'
          assert_select "a[style='display: none']", text: /Advanced filtering/
          assert_select "a[style='']", text: /Stop filtering/
        end
      end
    end
  end

  test 'no -advance filter- button when no invisible assets' do
    get '/logout' # to avoid redirect to select the profile for current user, when no person in the system
    with_config_value :faceted_browsing_enabled, true do
      ASSETS_WITH_FACET.each do |type_name|
        with_config_value :facet_enable_for_pages, type_name => true do
          klass = type_name.singularize.camelize.constantize
          klass.delete_all
          get "/#{type_name}"
          assert_select "div[id='no-index-items-text']"
          assert_select 'a', text: /Advanced filtering/, count: 0
        end
      end
    end
  end

  private

  def example_items
    ASSETS_WITH_FACET.each do |type_name|
      item = Factory(type_name.singularize.to_sym)
      next unless item.respond_to?(:policy)
      policy = item.policy
      policy.access_type = Policy::VISIBLE
      policy.save
      item.reload
    end
  end
end
