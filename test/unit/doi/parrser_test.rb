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

  test 'returns parsed data for a Crossref DOI' do
    VCR.use_cassette('doi/doi_crossref_response') do
      doi = '10.1038/s41586-020-2649-2'
      result = Seek::Doi::Parser.parse(doi)

      assert_equal result[:title],'Array programming with NumPy'
      assert_equal result[:doi], doi
      assert_includes result[:abstract],"Array programming provides a powerful"
      assert_equal result[:journal], "Nature"
      assert_equal result[:publisher], "Springer Science and Business Media LLC"
      assert_equal result[:published_date], '2020-09-16'
      assert_equal result[:publication_authors].first.full_name, 'Charles R. Harris'
      #assert_equal result[:citation], 'Nature. 585(7825). 2020.'
      #assert_equal result[:editors], nil
      assert_equal result[:booktitle], nil
      assert_equal result[:url], 'http://dx.doi.org/10.1038/s41586-020-2649-2'


    end
  end

end
