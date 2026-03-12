require 'test_helper'

class Seek::Doi::DataciteParserTest < ActiveSupport::TestCase

  test 'get_doi_ra returns DataCite for a known DOI' do
    VCR.use_cassette('doi/datacite_ra') do
      doi = '10.5281/zenodo.16736322'
      ra = Seek::Doi::Parser.send(:get_doi_ra, doi)
      assert_equal 'DataCite', ra
    end
  end


  # === Conference Paper ===
  test 'parses DOI (DataCite)_1' do
      VCR.use_cassette('doi/doi_datacite_response_1') do
        doi = '10.5281/zenodo.16736322'
        result = Seek::Doi::Parser.parse(doi)
        assert_equal result.title,'Flexible Metadata Structuring for Research Data Management Through the FAIRDOM-SEEK Platform - Implementing Tailored and Complex Metadata Schemes in SEEK'
        assert_equal result.type,'ConferencePaper'
        assert_equal result.doi, doi
        assert_match /Modern research projects increasingly require/, result.abstract
        assert_equal result.publisher, 'Zenodo'
        assert_equal result.date_published, '2025-01-01'
        assert_equal result.authors.first.full_name, 'Xiaoming Hu'
        assert_equal result.authors.size, 7
        assert_equal result.url, 'https://zenodo.org/doi/10.5281/zenodo.16736322'
      end
  end

  # === DataSet ===
  test 'parses DOI (DataCite)_2' do
    VCR.use_cassette('doi/doi_datacite_response_2') do
      doi = '10.5061/dryad.m62gj'
      result = Seek::Doi::Parser.parse(doi)
      assert_equal result.title, 'Data from: The hydrological legacy of deforestation on global wetlands'
      assert_equal result.type,'Dataset'
      assert_equal result.doi, doi
      assert_equal result.citation, 'Dryad. https://datadryad.org/dataset/doi:10.5061/dryad.m62gj.'
    end
  end

  # === Text ===
  #Li S, Gong M, Li Y-H, et al (2024) High spin axion insulator. arXiv. https://doi.org/10.48550/ARXIV.2404.12345
  test 'parses DOI (DataCite)_3' do
    VCR.use_cassette('doi/doi_datacite_response_3') do
      doi = '10.48550/arxiv.2404.12345'
      result = Seek::Doi::Parser.parse(doi)
      assert_equal result.title, 'High spin axion insulator'
      assert_equal result.type,'Text'
      assert_equal result.doi, doi
      assert_equal result.citation, 'arXiv. https://arxiv.org/abs/2404.12345.'
    end
  end

end

