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

  # Journal article
  test 'returns parsed Journal article DOI (crossref)' do
    VCR.use_cassette('doi/doi_crossref_journal_article_response') do
      doi = '10.1038/s41586-020-2649-2'
      result = Seek::Doi::Parser.parse(doi)
      puts result.inspect
      assert_equal result.title,'Array programming with NumPy'
      assert_equal result.doi, doi
      assert_equal result.abstract,'AbstractArray programming provides a powerful, compact and expressive syntax for accessing, manipulating and operating on data in vectors, matrices and higher-dimensional arrays. NumPy is the primary array programming library for the Python language. It has an essential role in research analysis pipelines in fields as diverse as physics, chemistry, astronomy, geoscience, biology, psychology, materials science, engineering, finance and economics. For example, in astronomy, NumPy was an important part of the software stack used in the discovery of gravitational waves1and in the first imaging of a black hole2. Here we review how a few fundamental array concepts lead to a simple and powerful programming paradigm for organizing, exploring and analysing scientific data. NumPy is the foundation upon which the scientific Python ecosystem is constructed. It is so pervasive that several projects, targeting audiences with specialized needs, have developed their own NumPy-like interfaces and array objects. Owing to its central position in the ecosystem, NumPy increasingly acts as an interoperability layer between such array computation libraries and, together with its application programming interface (API), provides a flexible framework to support the next decade of scientific and industrial analysis.'
      assert_equal result.journal, 'Nature'
      assert_equal result.publisher, 'Springer Science and Business Media LLC'
      assert_equal result.date_published, '2020-09-16'
      assert_equal result.authors.first.full_name, 'Charles R. Harris'
      #assert_equal result[:citation], 'Nature. 585(7825). 2020.'
      assert_equal result.url, 'http://dx.doi.org/10.1038/s41586-020-2649-2'
    end
  end

  # Book
  test 'returns parsed Journal article DOI with editors and subtitle (crossref)' do
    VCR.use_cassette('doi/doi_crossref_book_with_editor_subtitle_response') do
      doi = '10.2307/j.ctvn5txvs'
      result = Seek::Doi::Parser.parse(doi)

      assert_equal result.title, 'Troy Book:Selections'
      assert_equal result.doi, doi
      assert_nil result.abstract
      assert_empty result.journal
      assert_equal result.authors.first.full_name, 'John Lydgate'
      assert_equal result.editors, 'Robert R. Edwards'
      assert_equal result.publisher, 'Medieval Institute Publications'
      assert_equal result.url, 'http://dx.doi.org/10.2307/j.ctvn5txvs'
      assert_equal result.date_published, '1998-03-01'
      #assert_equal result[:citation], ''
    end
  end

  # Proceedings Article
  test 'returns parsed Proceedings Article DOI (crossref)' do
    VCR.use_cassette('doi/doi_crossref_proceedings_article_response') do
      doi = '10.1117/12.2275959'
      result = Seek::Doi::Parser.parse(doi)

      assert_equal result.title, 'The NOVA project: maximizing beam time efficiency through synergistic analyses of SRμCT data'
      assert_equal result.doi, doi
      assert_nil result.abstract
      assert_equal result.journal, 'Developments in X-Ray Tomography XI'
      assert_equal result.authors.first.full_name, 'Sebastian Schmelzle'
      assert_equal result.editors, 'Bert Müller and Ge Wang'
      assert_equal result.publisher, 'SPIE'
      assert_equal result.url, 'http://dx.doi.org/10.1117/12.2275959'
      assert_equal result.date_published, '2017-09-26'
      #assert_equal result.citation, ''
    end
  end

end
