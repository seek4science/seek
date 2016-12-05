#encoding: utf-8
require 'test_helper'

class SearchBiomodelsAdaptorTest < ActiveSupport::TestCase

  def setup
    mock_service_calls
  end

  test "initialize" do
    yaml = YAML.load_file("#{Rails.root}/test/fixtures/files/search_adaptor_config")
    adaptor = Seek::BiomodelsSearch::SearchBiomodelsAdaptor.new yaml
    assert !adaptor.enabled?
    assert_equal "lib/seek/biomodels_search/_biomodels_resource_list_item.html.erb",adaptor.partial_path
    assert_equal "BioModels Database",adaptor.name
    assert_equal "models",adaptor.search_type
  end

  test "search" do
    adaptor = Seek::BiomodelsSearch::SearchBiomodelsAdaptor.new({"partial_path" => "lib/test-partial.erb", "name" => "EBI Biomodels"})
    results = adaptor.search("yeast")
    assert_equal 14, results.count
    assert_equal 14, results.select { |r| r.kind_of?(Seek::BiomodelsSearch::BiomodelsSearchResult) }.count
    #results will all be the same due to the mocking of getSimpleModelById webservice call
    result = results.first
    assert_equal 34, result.authors.count
    assert_equal "M. J. Herrgard", result.authors.first
    assert_equal "Herrgård2008_MetabolicNetwork_Yeast", result.title
    assert_equal "18846089", result.publication_id
    assert_match(/Genomic data allow the large-scale manual or semi-automated assembly/, result.abstract)
    assert_equal DateTime.parse("2008-10-11"), result.published_date
    assert_equal "MODEL0072364382", result.model_id
    assert_equal DateTime.parse("2012-02-03T13:12:17+00:00"), result.last_modification_date
    assert_equal "lib/test-partial.erb", result.partial_path
    assert_equal "EBI Biomodels", result.tab
  end

  test "fetch_item" do
    adaptor = Seek::BiomodelsSearch::SearchBiomodelsAdaptor.new({"partial_path" => "lib/test-partial.erb", "name" => "EBI Biomodels"})
    result = adaptor.get_item("MODEL0072364382")
    assert result.kind_of?(Seek::BiomodelsSearch::BiomodelsSearchResult)

    #results will all be the same due to the mocking of getSimpleModelById webservice call
    assert_equal 34, result.authors.count
    assert_equal "M. J. Herrgard", result.authors.first
    assert_equal "Herrgård2008_MetabolicNetwork_Yeast", result.title
    assert_equal "18846089", result.publication_id
    assert_match(/Genomic data allow the large-scale manual or semi-automated assembly/, result.abstract)
    assert_equal DateTime.parse("2008-10-11"), result.published_date
    assert_equal "MODEL0072364382", result.model_id
    assert_equal DateTime.parse("2012-02-03T13:12:17+00:00"), result.last_modification_date
    assert_equal "lib/test-partial.erb", result.partial_path
    assert_equal "EBI Biomodels", result.tab
  end

  test "search does not need pubmed email" do
    adaptor = Seek::BiomodelsSearch::SearchBiomodelsAdaptor.new({"partial_path" => "lib/test-partial.erb"})
    results = adaptor.search("yeast")
    assert_equal 14, results.count
  end

  private

  def mock_service_calls
    wsdl = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels.wsdl")
    stub_request(:get, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices?wsdl").to_return(wsdl)

    response = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Soapaction'=>'"getModelsIdByName"'}).
        to_return(:status=>200,:body => response)

    response2 = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response2.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Soapaction'=>'"getModelsIdByChEBIId"'}).
        to_return(:status=>200,:body => response2)

    response3 = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response3.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Soapaction'=>'"getModelsIdByPerson"'}).
        to_return(:status=>200,:body => response3)

    response4 = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response4.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Soapaction'=>'"getSimpleModelById"'}).
        to_return(:status=>200,:body => response4.read)

    pub_response = File.new("#{Rails.root}/test/fixtures/files/mocking/pubmed_18846089.txt")
    stub_request(:post,"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi").
        to_return(:body=>pub_response)
  end

end
