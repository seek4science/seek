require 'test_helper'

class SearchBiomodelsAdaptorTest < ActiveSupport::TestCase

  def setup
    wsdl = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels.wsdl")
    stub_request(:get, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices?wsdl").to_return(wsdl)

    response = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Accept'=>'*/*', 'Content-Length'=>'503', 'Content-Type'=>'text/xml;charset=UTF-8', 'Soapaction'=>'"getModelsIdByName"'}).
        to_return(:body => response.read, :headers => {'Content-Type' => 'application/xml'})

    response2 = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response2.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Accept'=>'*/*', 'Content-Length'=>'505', 'Content-Type'=>'text/xml;charset=UTF-8', 'Soapaction'=>'"getModelsIdByChEBIId"'}).
        to_return(:body => response2.read, :headers => {'Content-Type' => 'application/xml'})

    response3 = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response3.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Accept'=>'*/*', 'Content-Length'=>'509', 'Content-Type'=>'text/xml;charset=UTF-8', 'Soapaction'=>'"getModelsIdByPerson"'}).
        to_return(:body => response3.read, :headers => {'Content-Type' => 'application/xml'})
  end

  test "search" do
    adaptor = Seek::SearchBiomodelsAdaptor.new({})
    results = adaptor.search("yeast")
    assert !results.empty?
  end





end