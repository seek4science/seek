require 'test_helper'
require 'minitest/mock'

class SearchControllerTest < ActionController::TestCase
  include RelatedItemsHelper

  test 'can render search results' do
    docs = FactoryBot.create_list(:public_document, 3)

    Document.stub(:solr_cache, -> (q) { Document.pluck(:id).last(3) }) do
      get :index, params: { q: 'test' }
    end

    assert_equal 3, assigns(:results)['Document'].count
    assert_select '#documents' do
      assert_select '.list_item_title', count: 3
      docs.each do |doc|
        assert_select '.list_item_title a[href=?]', document_path(doc)
      end
    end
  end

  test 'search result order retained' do
    FactoryBot.create_list(:public_document, 3)
    order = [Document.last, Document.third_to_last, Document.second_to_last]
    Document.stub(:solr_cache, -> (q) { order.collect { |d| d.id.to_s } }) do
      get :index, params: { q: 'test' }
    end

    order.each_with_index do |doc, idx|
      assert_select "#documents div.list_item[#{idx + 1}]" do
        assert_select 'a[href=?]', document_path(doc)
      end
    end
  end

  test 'can limit rendered search results' do
    FactoryBot.create_list(:public_document, 3)

    with_config_value(:search_results_limit, 1) do
      Document.stub(:solr_cache, -> (q) { Document.pluck(:id).last(3) }) do
        get :index, params: { q: 'test' }
      end
    end

    assert_equal 3, assigns(:results)['Document'].count
    assert_select '#documents .list_item_title', count: 1
  end

  test 'advanced search and filtering link' do
    FactoryBot.create_list(:public_document, 3)

    Document.stub(:solr_cache, -> (q) { Document.pluck(:id).last(3) }) do
      get :index, params: { q: 'test' }
    end

    assert_select '#documents a[href=?]', documents_path(filter: { query: 'test' }), text: /Advanced Documents search with filtering/
  end

  test 'can render external search results' do
    FactoryBot.create_list(:model, 3, policy: FactoryBot.create(:public_policy))

    VCR.use_cassette('biomodels/search') do
      with_config_value(:external_search_enabled, true) do
        Model.stub(:solr_cache, -> (q) { Model.pluck(:id).last(3) }) do
          get :index, params: { q: 'yeast', include_external_search: '1' }
        end
      end
    end

    assert_equal 3, assigns(:results)['Model'].count
    assert_equal 25, assigns(:external_results).count
    assert_select '.related-items li a', text: 'Models (3)'
    assert_select '.related-items li a', text: 'BioModels Database (25)'
    assert_select '#models .list_item_title', count: 3
    assert_select '#biomodels-databases .list_item_title', count: 25
  end

  test 'biomodels search can handle unreleased models' do
    VCR.use_cassette('biomodels/search-unreleased') do
      with_config_value(:external_search_enabled, true) do
        get :index, params: { q: '2024', include_external_search: '1', search_type:'models' }
      end
    end

    assert_select '.related-items li a', text: 'BioModels Database (6)'
    assert_equal 6, assigns(:external_results).count
    assert_equal 3, assigns(:external_results).select{|r| r.unreleased}.count
    assert_select '.related-items .list_item_attribute b', text: 'URL of original', count: 6
    assert_select '.related-items .list_item_attribute b', text: 'Publication date', count: 3
    assert_select '.related-items .list_item_actions', count: 3

  end

  test 'can render search results as valid JSON-API collection' do
    sops = FactoryBot.create_list(:public_sop, 2)
    docs = FactoryBot.create_list(:public_document, 3)

    Document.stub(:solr_cache, -> (q) { docs.map(&:id) }) do
      Sop.stub(:solr_cache, -> (q) { sops.map(&:id) }) do
        get :index, params: { q: 'something' }, format: :json
      end
    end

    perform_jsonapi_checks

    data = JSON.parse(response.body)['data']
    assert_equal 5, data.length
    sops.each do |sop|
      assert data.detect { |h| h['id'] == sop.id.to_s && h['type'] == 'sops' }
    end
    docs.each do |sop|
      assert data.detect { |h| h['id'] == sop.id.to_s && h['type'] == 'documents' }
    end
  end

  test 'limit does not apply to JSON search response' do
    sops = FactoryBot.create_list(:public_sop, 10)

    with_config_value(:search_results_limit, 1) do
      Sop.stub(:solr_cache, -> (q) { sops.map(&:id) }) do
        get :index, params: { q: 'something' }, format: :json
      end
    end

    perform_jsonapi_checks

    data = JSON.parse(response.body)['data']
    assert_equal 10, data.length
    sops.each do |sop|
      assert data.detect { |h| h['id'] == sop.id.to_s && h['type'] == 'sops' }
    end
  end

  test 'HTML in search term with no results is escaped' do
    Document.stub(:solr_cache, -> (q) { [] }) do
      get :index, params: { q: '<a href="#test-123">test</a>' }
    end

    assert_equal "No matches found for '<b>&lt;a href=&quot;#test-123&quot;&gt;test&lt;/a&gt;</b>'.", flash[:notice]
    assert_select 'a[href="#test-123"]', count: 0
  end

  test 'HTML in search term is escaped' do
    FactoryBot.create_list(:public_document, 1)

    Document.stub(:solr_cache, -> (q) { Document.pluck(:id).last(1) }) do
      get :index, params: { q: '<a id="xss123" href="#test-123">test</a>' }
    end

    assert_equal "1 item matched '<b>&lt;a href=&quot;#test-123&quot;&gt;test&lt;/a&gt;</b>' within their title or content.", flash[:notice]
    assert_select 'a[href="#test-123"]', count: 0
  end

  test 'link for more results' do
    FactoryBot.create_list(:public_document, 5)
    with_config_value(:search_results_limit, 2) do
      Document.stub(:solr_cache, -> (q) { Document.pluck(:id).last(5) }) do
        get :index, params: { q: 'test' }
      end
    end

    assert_select '#resources-shown-count',text:/Showing 2 out of a possible/
    assert_select '#resources-shown-count a[href=?]',documents_path('filter[query]':'test'), text:'5 Documents'
    assert_select '#more-results a[href=?]',documents_path('filter[query]':'test'), text:/View all 5 Documents/

    # not shown if within limit
    with_config_value(:search_results_limit, 6) do
      Document.stub(:solr_cache, -> (q) { Document.pluck(:id).last(5) }) do
        get :index, params: { q: 'test' }
      end
    end

    assert_select '#resources-shown-count', count:0
    assert_select '#more-results', count: 0

  end
end
