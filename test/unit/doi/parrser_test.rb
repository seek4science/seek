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

  # === JOURNAL ===
  test 'returns parsed Journal article DOI (crossref)' do
    VCR.use_cassette('doi/doi_crossref_journal_article_response') do
      doi = '10.1038/s41586-020-2649-2'
      result = Seek::Doi::Parser.parse(doi)
      #puts result.type.inspect
      assert_equal result.title,'Array programming with NumPy'
      assert_equal result.type,'journal-article'
      assert_equal result.doi, doi
      assert_equal result.abstract,'AbstractArray programming provides a powerful, compact and expressive syntax for accessing, manipulating and operating on data in vectors, matrices and higher-dimensional arrays. NumPy is the primary array programming library for the Python language. It has an essential role in research analysis pipelines in fields as diverse as physics, chemistry, astronomy, geoscience, biology, psychology, materials science, engineering, finance and economics. For example, in astronomy, NumPy was an important part of the software stack used in the discovery of gravitational waves1and in the first imaging of a black hole2. Here we review how a few fundamental array concepts lead to a simple and powerful programming paradigm for organizing, exploring and analysing scientific data. NumPy is the foundation upon which the scientific Python ecosystem is constructed. It is so pervasive that several projects, targeting audiences with specialized needs, have developed their own NumPy-like interfaces and array objects. Owing to its central position in the ecosystem, NumPy increasingly acts as an interoperability layer between such array computation libraries and, together with its application programming interface (API), provides a flexible framework to support the next decade of scientific and industrial analysis.'
      assert_equal result.journal, 'Nature'
      assert_equal result.publisher, 'Springer Science and Business Media LLC'
      assert_equal result.date_published, '2020-09-16'
      assert_equal result.authors.first.full_name, 'Charles R. Harris'
      #assert_equal result[:citation], 'Nature. 585(7825). 2020.'
      assert_equal result.url, 'https://doi.org/10.1038/s41586-020-2649-2'
    end
  end

  # === BOOK ===
  test 'returns parsed Journal article DOI with editors and subtitle (crossref)' do
    VCR.use_cassette('doi/doi_crossref_book_with_editor_subtitle_response') do
      doi = '10.2307/j.ctvn5txvs'
      result = Seek::Doi::Parser.parse(doi)
      #puts result.type.inspect
      assert_equal result.type, 'monograph'
      assert_equal result.title, 'Troy Book:Selections'
      assert_equal result.doi, doi
      assert_nil result.abstract
      assert_nil result.journal
      assert_equal result.authors.first.full_name, 'John Lydgate'
      assert_equal result.editors, 'Robert R. Edwards'
      assert_equal result.publisher, 'Medieval Institute Publications'
      assert_equal result.url, 'https://doi.org/10.2307/j.ctvn5txvs'
      assert_equal result.date_published, '1998-03-01'
      #assert_equal result[:citation], ''
    end
  end

  # === PROCEEDINGS ARTICLE ===
  test 'returns parsed Proceedings Article DOI (crossref)' do
    VCR.use_cassette('doi/doi_crossref_proceedings_article_response') do
      doi = '10.1117/12.2275959'
      result = Seek::Doi::Parser.parse(doi)
      assert_equal result.type, 'proceedings-article'
      assert_equal result.title, 'The NOVA project: maximizing beam time efficiency through synergistic analyses of SRμCT data'
      assert_equal result.doi, doi
      assert_nil result.abstract
      assert_equal result.journal, 'Developments in X-Ray Tomography XI'
      assert_equal result.authors.first.full_name, 'Sebastian Schmelzle'
      assert_equal result.editors, 'Bert Müller and Ge Wang'
      assert_equal result.publisher, 'SPIE'
      assert_equal result.url, 'https://doi.org/10.1117/12.2275959'
      assert_equal result.date_published, '2017-09-26'
      #assert_equal result.citation, ''
    end
  end

  #todo revisit!!!
  # === BOOK CHAPTER ===
  test 'parses Book Chapter DOI (Crossref)_1' do
    VCR.use_cassette('doi/doi_crossref_book_chapter_response_1') do
      doi = '10.1007/978-3-642-16239-8_8'
      result = Seek::Doi::Parser.parse(doi)
      assert_equal 'book-chapter', result.type
      assert_equal 'Prediction with Confidence Based on a Random Forest Classifier', result.title
      assert_equal doi, result.doi
      assert_nil result.abstract
      assert_equal 'Dmitry Devetyarov', result.authors.first.full_name
      assert_equal 'Ilia Nouretdinov', result.authors.last.full_name
      assert_empty result.editors
      assert_equal 'Springer Berlin Heidelberg', result.publisher
      assert_equal '2010-01-01', result.date_published
      assert_equal 'https://doi.org/10.1007/978-3-642-16239-8_8', result.url
      assert_equal "In: Artificial Intelligence Applications and Innovations. Springer Berlin Heidelberg, Berlin, Heidelberg, pp 37-44", result.citation

    end
    end

  test 'parses Book Chapter DOI (Crossref)_2' do
    VCR.use_cassette('doi/doi_crossref_book_chapter_response_2') do
      doi = '10.1007/978-3-540-70504-8_9'
      result = Seek::Doi::Parser.parse(doi)
      assert_equal result.type, 'book-chapter'
      assert_equal 'book-chapter', result.type
      assert_equal 'A Semantics for a Query Language over Sensors, Streams and Relations', result.title
      assert_equal doi, result.doi
      assert_nil result.abstract
      assert_equal 4, result.authors.size
      assert_equal 'Christian Y. A. Brenninkmeijer', result.authors[0].full_name
      assert_empty result.editors
      assert_equal 'Springer Berlin Heidelberg', result.publisher
      assert_equal 'Sharing Data, Information and Knowledge', result.booktitle
      assert_equal 'Sharing Data, Information and Knowledge', result.journal
      assert_equal '87-99', result.page
      assert_equal 'https://doi.org/10.1007/978-3-540-70504-8_9', result.url
      assert_equal 'In: Sharing Data, Information and Knowledge. Springer Berlin Heidelberg, Berlin, Heidelberg, pp 87-99', result.citation

    end
  end

  test 'parses Book Chapter DOI (Crossref)_3' do
    VCR.use_cassette('doi/doi_crossref_book_chapter_response_3') do
      doi = '10.1007/978-3-642-16239-8_8'
      result = Seek::Doi::Parser.parse(doi)
      assert_equal 'book-chapter', result.type
      assert_equal 'Prediction with Confidence Based on a Random Forest Classifier', result.title
      assert_equal doi, result.doi
      assert_nil result.abstract
      assert_equal 2, result.authors.size
      assert_equal 'Dmitry Devetyarov', result.authors.first.full_name
      assert_empty result.editors
      assert_equal 'Springer Berlin Heidelberg', result.publisher
      assert_equal '2010-01-01', result.date_published
      assert_equal 'https://doi.org/10.1007/978-3-642-16239-8_8', result.url
      assert_equal 'Artificial Intelligence Applications and Innovations', result.booktitle
      assert_equal 'Artificial Intelligence Applications and Innovations', result.journal
      assert_equal '37-44', result.page
      assert_equal 'In: Artificial Intelligence Applications and Innovations. Springer Berlin Heidelberg, Berlin, Heidelberg, pp 37-44', result.citation

    end
  end



end
