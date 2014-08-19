require 'test_helper'

class FacetedBrowsingTest < ActionController::IntegrationTest

  ASSETS_WITH_FACET = Seek::Config.facet_enable_for_pages.keys

  def setup
    User.current_user = Factory(:user, :login => 'test')
    post '/session', :login => 'test', :password => 'blah'
  end

  test 'turn off the faceted browsing' do
    with_config_value :faceted_browsing_enabled,false do
      ASSETS_WITH_FACET.each do |type_name|
        get "/#{type_name}"
        assert_select "table[id='exhibit']", :count => 0
        assert_select "div.alphabetcal_pagination"
      end
    end

  end

  test 'turn on the faceted browsing' do
    with_config_value :faceted_browsing_enabled,true do
      ASSETS_WITH_FACET.each do |type_name|
        with_config_value :facet_enable_for_pages,{type_name=>true} do
          get "/#{type_name}"
          assert_select "div[id='exhibit']"
          assert_select "div.alphabetcal_pagination", :count => 0
        end
      end
    end

  end

  test 'partly turn on the faceted browsing' do
    with_config_value :faceted_browsing_enabled,true do
      facet_enabled_pages = {}
      facet_disabled_pages = {}
      Seek::Config.facet_enable_for_pages.each do |key,value|
        if value == true
          facet_enabled_pages[key] = value
        else
          facet_disabled_pages[key] = value
        end
      end

      assert !facet_enabled_pages.blank?
      assert !facet_disabled_pages.blank?

      facet_enabled_pages.keys.each do |type_name|
        get "/#{type_name}"
        assert_select "div[id='exhibit']"
        assert_select "div.alphabetcal_pagination", :count => 0
      end

      facet_disabled_pages.keys.each do |type_name|
        get "/#{type_name}"
        assert_select "div[id='exhibit']", :count => 0
        assert_select "div.alphabetcal_pagination"
      end
    end

  end
end