require 'test_helper'

class FacetedBrowsingTest < ActionController::IntegrationTest
  ASSETS_WITH_FACET = Seek::Config.facet_enable_for_pages.keys

  def setup
    User.current_user = Factory(:user, :login => 'test')
    post '/session', :login => 'test', :password => 'blah'
  end

  test 'turn off the faceted browsing' do
    Seek::Config.faceted_browsing_enabled = false
    ASSETS_WITH_FACET.each do |type_name|
      get "/#{type_name}"
      assert_select "div[id='exhibit']", :count => 0
      assert_select "div.alphabetcal_pagination"
    end
  end

  test 'turn on the faceted browsing' do
    Seek::Config.faceted_browsing_enabled = true
    ASSETS_WITH_FACET.each do |type_name|
      Seek::Config.set_facet_enable_for_page(type_name, true)
    end

    ASSETS_WITH_FACET.each do |type_name|
      get "/#{type_name}"
      assert_select "div[id='exhibit']"
      assert_select "div.alphabetcal_pagination", :count => 0
    end
  end

  test 'partly turn on the faceted browsing' do
    Seek::Config.faceted_browsing_enabled = true
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

  test 'facet config for Assay' do
    Seek::Config.faceted_browsing_enabled = true
    Seek::Config.set_facet_enable_for_page('assays', true)

    get "/assays"
    assert_select "div[data-ex-facet-class='TextSearch']", :count => 1
    assert_select "div[data-ex-role='facet'][data-ex-expression='.organism']", :count => 1
    assert_select "div[data-ex-role='facet'][data-ex-expression='.assay_type'][data-ex-facet-class='Exhibit.HierarchicalFacet']", :count => 1
    assert_select "div[data-ex-role='facet'][data-ex-expression='.technology_type'][data-ex-facet-class='Exhibit.HierarchicalFacet']", :count => 0
    assert_select "div[data-ex-role='facet'][data-ex-expression='.project']", :count => 0
  end

  test 'content config for Assay' do
    Seek::Config.faceted_browsing_enabled = true
    Seek::Config.set_facet_enable_for_page('assays', true)

    get "/assays"
    assert_select "div[data-ex-role='exhibit-view'][data-ex-label='Tiles'][data-ex-paginate='true'][data-ex-page-size='10']", :count => 1
  end

  test 'show only authorized items' do
    Seek::Config.faceted_browsing_enabled = true
    Seek::Config.set_facet_enable_for_page('assays', true)
    assay1 = Factory(:assay, :policy => Factory(:public_policy))
    assay2 = Factory(:assay, :policy => Factory(:private_policy))
    assert assay1.can_view?
    assert !assay2.can_view?

    xhr(:get, "/assays/faceted_items",{:item_type => 'Assay', :item_ids => [assay1.id,assay2.id]})
    resource_list_items =  ActiveSupport::JSON.decode(@response.body)['resource_list_items']
    assert resource_list_items.include?(assay1.title)
    assert !resource_list_items.include?(assay2.title)
  end
end