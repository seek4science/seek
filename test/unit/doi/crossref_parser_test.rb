require 'test_helper'

module Seek
  module Doi
    class CrossrefParserTest < ActiveSupport::TestCase


      test 'get_doi_ra returns Crossref for a known DOI' do
        VCR.use_cassette('doi/crossref_ra') do
          doi = '10.1038/s41586-020-2649-2'
          ra = Seek::Doi::Parser.send(:get_doi_ra, doi)
          assert_equal 'Crossref', ra
        end
      end


    # === JOURNAL ===
      test 'returns parsed journal article DOI (crossref)_1' do
        VCR.use_cassette('doi/doi_crossref_journal_article_response_1') do
          doi = '10.1038/s41586-020-2649-2'
          result = Seek::Doi::Parser.parse(doi)
          assert_equal result.title,'Array programming with NumPy'
          assert_equal result.type,'journal-article'
          assert_equal result.doi, doi
          assert_equal result.abstract,'AbstractArray programming provides a powerful, compact and expressive syntax for accessing, manipulating and operating on data in vectors, matrices and higher-dimensional arrays. NumPy is the primary array programming library for the Python language. It has an essential role in research analysis pipelines in fields as diverse as physics, chemistry, astronomy, geoscience, biology, psychology, materials science, engineering, finance and economics. For example, in astronomy, NumPy was an important part of the software stack used in the discovery of gravitational waves1and in the first imaging of a black hole2. Here we review how a few fundamental array concepts lead to a simple and powerful programming paradigm for organizing, exploring and analysing scientific data. NumPy is the foundation upon which the scientific Python ecosystem is constructed. It is so pervasive that several projects, targeting audiences with specialized needs, have developed their own NumPy-like interfaces and array objects. Owing to its central position in the ecosystem, NumPy increasingly acts as an interoperability layer between such array computation libraries and, together with its application programming interface (API), provides a flexible framework to support the next decade of scientific and industrial analysis.'
          assert_equal result.journal, 'Nature'
          assert_equal result.publisher, 'Springer Science and Business Media LLC'
          assert_equal result.date_published, '2020-09-16'
          assert_equal result.authors.first.full_name, 'Charles R. Harris'
          assert_equal result[:citation], 'Nature 585(7825):357-362.'
          assert_equal result.url, 'https://doi.org/10.1038/s41586-020-2649-2'
        end
      end

      test 'returns parsed journal article DOI (crossref)_2' do
        VCR.use_cassette('doi/doi_crossref_journal_article_response_2') do
          doi = '10.1021/acs.jcim.5c01488'
          result = Seek::Doi::Parser.parse(doi)

          assert_equal 'journal-article', result.type
          assert_equal 'A Multiscale Simulation Approach to Compute Protein–Ligand Association Rate Constants by Combining Brownian Dynamics and Molecular Dynamics', result.title
          assert_equal doi, result.doi
          assert_nil result.abstract
          assert_equal 'Abraham Muñiz-Chicharro', result.authors[0].full_name
          assert_equal 'Gaurav K. Ganotra', result.authors[1].full_name
          assert_equal 'Rebecca C. Wade', result.authors[2].full_name
          assert_empty result.editors
          assert_equal 'American Chemical Society (ACS)', result.publisher
          assert_equal '2025-10-04', result.date_published
          assert_equal 'Journal of Chemical Information and Modeling', result.booktitle
          assert_equal 'Journal of Chemical Information and Modeling', result.journal
          assert_equal 'https://doi.org/10.1021/acs.jcim.5c01488', result.url
          assert_equal 'J. Chem. Inf. Model. 65(20):11215-11231.', result.citation

        end
      end


    # === MONOGRAPH ===
      test 'returns parsed journal article DOI with editors and subtitle (crossref)' do
        VCR.use_cassette('doi/doi_crossref_book_with_editor_subtitle_response') do
          doi = '10.2307/j.ctvn5txvs'
          result = Seek::Doi::Parser.parse(doi)
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
          assert_equal result[:citation], 'Medieval Institute Publications'
        end
      end

    # === PROCEEDINGS ARTICLE ===
      test 'returns parsed proceedings article DOI (crossref)_1' do
        VCR.use_cassette('doi/doi_crossref_proceedings_article_response_1') do
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
          assert_equal result.citation, 'In: Developments in X-Ray Tomography XI. SPIE, San Diego, United States, p 24'
        end
      end


      test 'returns parsed proceedings article DOI (crossref)_2' do
        VCR.use_cassette('doi/doi_crossref_proceedings_article_response_2') do
          doi = '10.1145/3292500.3330675'
          result = Seek::Doi::Parser.parse(doi)
          assert_equal 'proceedings-article', result.type
          assert_equal 'Whole Page Optimization with Global Constraints', result.title
          assert_equal doi, result.doi
          assert_nil result.abstract
          assert_equal 'Weicong Ding', result.authors[0].full_name
          assert_equal 3, result.authors.size
          assert_empty result.editors
          assert_equal 'ACM', result.publisher
          assert_equal '2019-07-25', result.date_published
          assert_equal 'Proceedings of the 25th ACM SIGKDD International Conference on Knowledge Discovery & Data Mining', result.booktitle
          assert_equal 'Proceedings of the 25th ACM SIGKDD International Conference on Knowledge Discovery & Data Mining', result.journal
          assert_equal '3153-3161', result.page
          assert_equal 'https://doi.org/10.1145/3292500.3330675', result.url
          assert_equal 'In: Proceedings of the 25th ACM SIGKDD International Conference on Knowledge Discovery & Data Mining. ACM, Anchorage AK USA, pp 3153-3161', result.citation

        end
      end

      test 'returns parsed proceedings article DOI (crossref)_3' do
        VCR.use_cassette('doi/doi_crossref_proceedings_article_response_3') do
          doi = '10.1063/1.2128263'
          result = Seek::Doi::Parser.parse(doi)
          assert_equal 'proceedings-article', result.type
          assert_equal 'Conference Recommendations', result.title
          assert_equal doi, result.doi
          assert_nil result.abstract
          assert_equal 'Conference organizers ', result.authors.first.full_name
          assert_empty result.editors
          assert_equal 'AIP', result.publisher
          assert_equal '2005-01-01', result.date_published
          assert_equal 'AIP Conference Proceedings', result.booktitle
          assert_equal 'AIP Conference Proceedings', result.journal
          assert_equal '29-34', result.page
          assert_equal 'https://doi.org/10.1063/1.2128263', result.url
          assert_equal 'In: AIP Conference Proceedings. AIP, Rio de Janeiro (Brazil), pp 29-34', result.citation
        end
      end

    # === PROCEEDINGS ===
      test 'returns parsed proceedings DOI (crossref)_1' do
        VCR.use_cassette('doi/doi_crossref_proceedings_response_1') do
          doi = '10.18653/v1/w18-08'
          result = Seek::Doi::Parser.parse(doi)
          assert_equal result.type, 'proceedings'
          assert_equal 'Proceedings of the Second ACL Workshop on Ethics in Natural Language Processing', result.title
          assert_equal doi, result.doi
          assert_equal 'Association for Computational Linguistics', result.publisher
          assert_equal '2018-01-01', result.date_published
          assert_equal 'https://doi.org/10.18653/v1/w18-08', result.url
          assert_equal 'Proceedings of the Second ACL Workshop on Ethics in Natural Language Processing. Association for Computational Linguistics, New Orleans, Louisiana, USA', result.citation
        end
      end



    # === BOOK CHAPTER ===
      test 'parses book chapter DOI (Crossref)_1' do
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

      test 'parses book chapter DOI (Crossref)_2' do
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

      test 'parses book chapter DOI (Crossref)_3' do
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


    # === BOOK ===
    # more book doi: 10.1007/978-3-662-49096-9
      test 'parses book DOI (Crossref)_1' do
        VCR.use_cassette('doi/doi_crossref_book_response_1') do
          doi = '10.23943/princeton/9780691161914.003.0002'
          result = Seek::Doi::Parser.parse(doi)
          assert_equal 'book', result.type
          assert_equal "Milton’s Book of Numbers: Book 1 and Its Catalog", result.title
          assert_equal doi, result.doi
          assert_match(/Paradise Lost/, result.abstract)
          assert_equal 'David Quint', result.authors.first.full_name
          assert_equal 1, result.authors.size
          assert_empty result.editors
          assert_equal 'Princeton University Press', result.publisher
          assert_equal '2017-10-19', result.date_published
          assert_equal 'Princeton University Press', result.booktitle
          assert_equal 'Princeton University Press', result.journal
          assert_equal 'https://doi.org/10.23943/princeton/9780691161914.003.0002', result.url
          assert_equal 'Princeton University Press', result.citation
        end
      end

      test 'parses book DOI (Crossref)_2' do
        VCR.use_cassette('doi/doi_crossref_book_response_2') do
          doi = '10.1007/978-3-540-70504-8'
          result = Seek::Doi::Parser.parse(doi)
          assert_equal 'book', result.type
          assert_equal 'Sharing Data, Information and Knowledge:25th British National Conference on Databases, BNCOD 25, Cardiff, UK, July 7-10, 2008. Proceedings', result.title
          assert_equal doi, result.doi
          assert_nil result.abstract
          assert_empty result.authors
          assert_equal 'Alex Gray and Keith Jeffery and Jianhua Shao', result.editors
          assert_equal 'Springer Berlin Heidelberg', result.publisher
          assert_equal '2008-01-01', result.date_published
          assert_equal 'Lecture Notes in Computer Science', result.booktitle
          assert_equal 'Lecture Notes in Computer Science', result.journal
          assert_equal 'https://doi.org/10.1007/978-3-540-70504-8', result.url
          assert_equal 'Springer Berlin Heidelberg, Berlin, Heidelberg', result.citation
        end
      end


    # === PREPRINT ===

      test 'parses preprint DOI (Crossref)_1' do
        VCR.use_cassette('doi/doi_crossref_preprint_response_1') do
          doi = '10.20944/preprints201909.0043.v1'
          result = Seek::Doi::Parser.parse(doi)
          assert_equal 'posted-content', result.type
          assert_equal 'An Isolated Complex V Inefficiency and Dysregulated Mitochondrial Function in Immortalized Lymphocytes from ME/CFS Patients', result.title
          assert_equal doi, result.doi
          assert_equal 'https://doi.org/10.20944/preprints201909.0043.v1', result.url
          assert_equal '2019-09-04', result.date_published
          assert_equal  'Preprint. https://doi.org/10.20944/preprints201909.0043.v1', result.citation
        end
      end
    end
  end
end

