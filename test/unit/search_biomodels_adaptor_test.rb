# encoding: utf-8
require 'test_helper'

class SearchBiomodelsAdaptorTest < ActiveSupport::TestCase


  test 'initialize' do
    yaml = YAML.load_file("#{Rails.root}/test/fixtures/files/search_adaptor_config")
    adaptor = Seek::BiomodelsSearch::SearchBiomodelsAdaptor.new yaml
    assert !adaptor.enabled?
    assert_equal 'search/partials/biomodels_resource_list_item', adaptor.partial_path
    assert_equal 'BioModels Database', adaptor.name
    assert_equal 'models', adaptor.search_type
  end

  test 'search' do
    VCR.use_cassette('biomodels/search') do
      adaptor = Seek::BiomodelsSearch::SearchBiomodelsAdaptor.new('partial_path' => 'search/partials/test_partial', 'name' => 'EBI Biomodels')
      results = adaptor.search('yeast')
      assert_equal 25, results.count
      assert_equal 25, results.count { |r| r.is_a?(Seek::BiomodelsSearch::BiomodelsSearchResult) }
      # results will all be the same due to the mocking of getSimpleModelById webservice call
      result = results.first
      assert_equal 5, result.authors.count
      assert_equal 'Schaber J', result.authors.first
      assert_equal 'Schaber2012 - Hog pathway in yeast', result.title
      #assert_equal '18846089', result.publication_id
      assert_match(/The high osmolarity glycerol \(HOG\) pathway in the yeast Saccharomyces cerevisiae/, result.abstract)
      assert_equal DateTime.parse('2012-11-22 18:31:29 +0000'), result.published_date
      assert_equal 'BIOMD0000000429', result.model_id
      assert_equal DateTime.parse('2012-12-14 14:24:40 +0000'), result.last_modification_date
      assert_equal 'search/partials/test_partial', result.partial_path
      assert_equal 'EBI Biomodels', result.tab
    end

  end

  test 'fetch_item' do
    VCR.use_cassette('biomodels/fetch_item') do
      adaptor = Seek::BiomodelsSearch::SearchBiomodelsAdaptor.new('partial_path' => 'search/partials/test_partial', 'name' => 'EBI Biomodels')
      result = adaptor.get_item('BIOMD0000000429')
      assert result.is_a?(Seek::BiomodelsSearch::BiomodelsSearchResult)

      # results will all be the same due to the mocking of getSimpleModelById webservice call
      assert_equal 5, result.authors.count
      assert_equal 'Schaber J', result.authors.first
      assert_equal 'Schaber2012 - Hog pathway in yeast', result.title
      #assert_equal '18846089', result.publication_id
      assert_match(/The high osmolarity glycerol \(HOG\) pathway in the yeast Saccharomyces cerevisiae/, result.abstract)
      assert_equal DateTime.parse('2012-11-22 18:31:29 +0000'), result.published_date
      assert_equal 'BIOMD0000000429', result.model_id
      assert_equal DateTime.parse('2012-12-14 14:24:40 +0000'), result.last_modification_date
      assert_equal 'search/partials/test_partial', result.partial_path
      assert_equal 'EBI Biomodels', result.tab
      assert_equal 'BIOMD0000000429_url.xml', result.main_filename
    end

  end

  test 'search does not need pubmed email' do
    VCR.use_cassette('biomodels/search') do
      adaptor = Seek::BiomodelsSearch::SearchBiomodelsAdaptor.new('partial_path' => 'search/partials/test_partial')
      results = adaptor.search('yeast')
      assert_equal 25, results.count
    end
  end

  test 'search does not files' do
    VCR.use_cassette('biomodels/search-2024') do
      adaptor = Seek::BiomodelsSearch::SearchBiomodelsAdaptor.new('partial_path' => 'search/partials/test_partial')
      results = adaptor.search('2024')
      assert_equal 25, results.count
    end
  end


end
