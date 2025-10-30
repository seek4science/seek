require 'test_helper'

class DoiParserExceptionTest < ActiveSupport::TestCase

  test 'raises RANotSupported for mEDRA DOI' do
    VCR.use_cassette('doi/medra_ra') do
      doi = '10.19232/uv4pb.2018.2.00'
      assert_equal 'mEDRA', Seek::Doi::Parser.send(:get_doi_ra, doi)
    end
  end

  # Test that a DOI registered under mEDRA raises the correct exception
  test 'raises RANotSupported for mEDRA DOI11' do
    VCR.use_cassette('doi/medra_ra') do
      doi = '10.19232/uv4pb.2018.2.00'
      error = assert_raises(Seek::Doi::RANotSupported) do
        Seek::Doi::Parser.parse(doi)
      end
      assert_equal "DOI registration agency 'mEDRA' is not supported.", error.message
    end
  end


  test 'raises NotFoundException for fake DOI' do
    VCR.use_cassette('doi/fake_doi') do
      doi = '10.19232/fake.2020.1.23'
      error = assert_raises(Seek::Doi::NotFoundException) do
        Seek::Doi::Parser.send(:get_doi_ra, doi)
      end
      assert_equal 'DOI does not exist: 10.19232/fake.2020.1.23.', error.message
    end
  end

  test 'raises MalformedDOIException for invalid DOI' do
    VCR.use_cassette('doi/invalid_doi') do
      doi = 'hello_march'
      error = assert_raises(Seek::Doi::MalformedDOIException) do
        Seek::Doi::Parser.send(:get_doi_ra, doi)
      end
      assert_equal 'Invalid DOI format: hello_march.', error.message
    end
  end


  test 'raises ParseException when Crossref returns invalid JSON' do
    doi = '10.1016/j.patter.2025.101345'

    VCR.use_cassette('doi/invalid_json_response') do
      error = assert_raises(Seek::Doi::ParseException) do
        Seek::Doi::Parser.parse(doi)
      end
      assert_match /Error parsing JSON for DOI/, error.message
    end
  end

end


# resource not found
#10.31234/osf.io/8s4xq

# phd thesis can not be resolved
#10.5445/IR/1000055628