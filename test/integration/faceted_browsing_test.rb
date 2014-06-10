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

  test 'facet config for Assay' do
    Factory(:assay, :policy => Factory(:public_policy))
    with_config_value :faceted_browsing_enabled,true do
      get "/assays"
      record_body
      assert_select "div[data-ex-facet-class='TextSearch']", :count => 1
      assert_select "div[data-ex-role='facet'][data-ex-expression='.organism']", :count => 1
      assert_select "div[data-ex-role='facet'][data-ex-expression='.assay_type'][data-ex-facet-class='Exhibit.HierarchicalFacet']", :count => 1
      assert_select "div[data-ex-role='facet'][data-ex-expression='.technology_type'][data-ex-facet-class='Exhibit.HierarchicalFacet']", :count => 0
      assert_select "div[data-ex-role='facet'][data-ex-expression='.project']", :count => 0
    end



  end

  test 'content config for Assay' do
    with_config_value :faceted_browsing_enabled,true do
      get "/assays"
      assert_select "div[data-ex-role='exhibit-view'][data-ex-label='Tiles'][data-ex-paginate='true'][data-ex-page-size='10']", :count => 1
    end
  end

  test 'show only authorized items' do
    with_config_value :faceted_browsing_enabled,true do
      assay1 = Factory(:assay, :policy => Factory(:public_policy))
      assay2 = Factory(:assay, :policy => Factory(:private_policy))
      assert assay1.can_view?
      assert !assay2.can_view?

      xhr(:get, "/assays/items_for_result",{:item_type => 'Assay', :item_ids => [assay1.id,assay2.id]})
      items_for_result =  ActiveSupport::JSON.decode(@response.body)['items_for_result']
      assert items_for_result.include?(assay1.title)
      assert !items_for_result.include?(assay2.title)
    end
  end
end