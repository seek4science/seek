require 'test_helper'
require 'minitest/mock'

class SearchControllerTest < ActionController::TestCase
  include JsonTestHelper

  test 'can render search results' do
    docs = FactoryGirl.create_list(:public_document, 3)

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

  test 'can limit rendered search results' do
    FactoryGirl.create_list(:public_document, 3)

    with_config_value(:search_results_limit, 1) do
      Document.stub(:solr_cache, -> (q) { Document.pluck(:id).last(3) }) do
        get :index, params: { q: 'test' }
      end
    end

    assert_equal 3, assigns(:results)['Document'].count
    assert_select '#documents .list_item_title', count: 1
    assert_select '#documents a[href=?]', documents_path(filter: { query: 'test' }), text: 'View all 3 items'
  end

  test 'can render external search results' do
    FactoryGirl.create_list(:model, 3, policy: Factory(:public_policy))

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

  test 'can render search results as valid JSON-API collection' do
    sops = FactoryGirl.create_list(:public_sop, 2)
    docs = FactoryGirl.create_list(:public_document, 3)

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
    sops = FactoryGirl.create_list(:public_sop, 10)

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
end
