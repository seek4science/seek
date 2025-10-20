require 'test_helper'

class Seek::Doi::ParserTest < ActiveSupport::TestCase

  test 'returns nil if DOI is blank' do
    result = Seek::Doi::Parser.parse('')
    assert_nil result

    result = Seek::Doi::Parser.parse(nil)
    assert_nil result
  end

  test 'get_doi_ra returns DataCite for a known DOI' do
    VCR.use_cassette('doi/datacite_ra') do
      doi = '10.5281/zenodo.16736322'
      ra = Seek::Doi::Parser.send(:get_doi_ra, doi)
      assert_equal 'DataCite', ra
    end
  end

  test 'get_doi_ra returns Crossref for a known DOI' do
    VCR.use_cassette('doi/crossref_ra') do
      doi = '10.1038/s41586-020-2649-2'

      ra = Seek::Doi::Parser.send(:get_doi_ra, doi)
      assert_equal 'Crossref', ra
    end
  end

end
