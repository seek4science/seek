require 'test_helper'

class PublicationTest < ActiveSupport::TestCase
  include MockHelper

  fixtures :all

  test 'title validation allows long titles' do
    long_title = ('a' * 65536).freeze
    ok_title = ('a' * 65535).freeze
    p = FactoryBot.create(:publication)
    assert p.valid?
    p.title = long_title
    refute p.valid?
    p.title = ok_title
    assert p.valid?
    disable_authorization_checks{p.save!}

  end

  test 'publication type validation' do

    # new publication must have a publication type
    project = FactoryBot.create(:project)
    p1 = Publication.new(title: 'test1', projects: [project], doi: '10.5072/abc',publication_type_id:nil)
    assert !p1.valid?

    # allow old publications without publication type
    p2 = FactoryBot.create(:publication)
    p2.publication_type_id = nil
    disable_authorization_checks { p2.save! }
    assert p2.valid?
  end

  test 'create publication from hash' do
    publication_hash = {
        title: 'SEEK publication',
        abstract: 'An investigation into blalblabla',
        journal: 'The testing journal',
        published_date: Date.new(2011, 12, 24),
        pubmed_id: nil,
        doi: nil
    }
    publication = Publication.new(publication_hash)
    assert_equal publication_hash[:title], publication.title
    assert_equal publication_hash[:journal], publication.journal
    assert_equal publication_hash[:published_date], publication.published_date
    assert_equal publication_hash[:abstract], publication.abstract
    assert_nil publication.pubmed_id
    assert_nil publication.doi
  end

  test 'create publication from metadata doi' do
    publication_hash = {
        title: 'SEEK publication',
        abstract: 'An investigation into blalblabla',
        journal: 'The testing journal',
        date_published: Date.new(2011, 12, 24),
        pubmed_id: nil,
        doi: nil
    }
    doi_record = DOI::Record.new(publication_hash)
    publication = Publication.new
    publication.extract_doi_metadata(doi_record)
    assert_equal publication_hash[:title], publication.title
    assert_equal publication_hash[:journal], publication.journal
    assert_equal publication_hash[:date_published], publication.published_date
    assert_equal publication_hash[:abstract], publication.abstract
    assert_nil publication.pubmed_id
    assert_nil publication.doi
    assert_equal Publication::REGISTRATION_BY_DOI, publication.registered_mode
  end

  test 'create publication from metadata pubmed' do
    publication_hash = {
        'title'   => 'SEEK publication\\r', # test required? chomp
        'abstract' => 'An investigation into blalblabla',
        'journal' => 'The testing journal',
        'pubmed' => nil,
        'doi' => nil
    }
    bio_reference = Bio::Reference.new(publication_hash)
    publication = Publication.new
    publication.extract_pubmed_metadata(bio_reference)
    assert_equal publication_hash[:title.to_s], publication.title
    assert_equal publication_hash[:journal.to_s], publication.journal
    assert_equal publication_hash[:abstract.to_s], publication.abstract
    assert_nil publication.pubmed_id
    assert_nil publication.doi
    assert_equal Publication::REGISTRATION_BY_PUBMED, publication.registered_mode
  end

  test 'create publication from metadata bibtex' do
    require 'bibtex'
    bibtex = BibTeX.parse <<-END
    @article{PMID:26018949,
      author       = {Putnam, D. K. and Weiner, B. E. and Woetzel, N. and Lowe, E. W. Jr and Meiler, J.},
      title        = {BCL::SAXS},
      journal      = {Proteins},
      year         = {2015},
      abstract     = {An investigation into blalblabla},
      volume       = {83},
      number       = {8},
      pages        = {1500--1512},
      url          = {http://www.ncbi.nlm.nih.gov/pubmed/26018949},
    }
    END

    publication = Publication.new
    publication.extract_bibtex_metadata(bibtex['@article'][0])
    assert_equal 'BCL::SAXS', publication.title
    assert_equal 'Proteins', publication.journal
    assert_equal 'An investigation into blalblabla', publication.abstract
    assert_equal Date.new(2015, 1, 1), publication.published_date
    assert_equal 5, publication.publication_authors.length
    assert_equal Publication::REGISTRATION_FROM_BIBTEX, publication.registered_mode
  end

  test 'event association' do
    publication = FactoryBot.create :publication
    assert publication.events.empty?
    event = events(:event_with_no_files)
    User.with_current_user(publication.contributor) do
      publication.events << event
      assert publication.valid?
      publication.save!
    end
    publication = Publication.find(publication.id)
    assert_equal 1, publication.events.count
  end

  test 'to_rdf' do
    object = FactoryBot.create :publication
    FactoryBot.create :relationship, subject: FactoryBot.create(:assay), other_object: object, predicate: Relationship::RELATED_TO_PUBLICATION
    object.reload

    rdf = object.to_rdf
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(rdf) {|reader| graph << reader}
    end

    assert graph.statements.count >= 1
    assert_equal RDF::URI.new("http://localhost:3000/publications/#{object.id}"), graph.statements.first.subject

  end

  test 'content blob search terms' do
    p = FactoryBot.create :publication
    assert_equal [], p.content_blob_search_terms
  end

  test 'associate' do
    publication = FactoryBot.create(:publication)
    assay = FactoryBot.create(:assay)
    data_file = FactoryBot.create(:data_file)
    model = FactoryBot.create(:model)

    publication.associate(assay)
    publication.associate(data_file)
    publication.associate(model)
    User.with_current_user publication.contributor do
      publication.save!
    end
    assert_equal [assay], publication.assays
    assert_equal [data_file], publication.data_files
    assert_equal [model], publication.models
  end

  test 'related organisms' do
    organism1 = FactoryBot.create(:organism)
    organism2 = FactoryBot.create(:organism)
    publication = FactoryBot.create(:publication)
    model1 = FactoryBot.create(:model, organism: organism1)
    assay1 = FactoryBot.create(:assay, organisms: [organism1])
    model2 = FactoryBot.create(:model, organism: organism2)
    assay2 = FactoryBot.create(:assay, organisms: [organism2])
    publication.associate(model1)
    publication.associate(model2)
    publication.associate(assay1)
    publication.associate(assay2)
    User.with_current_user publication.contributor do
      publication.save!
    end

    assert_equal [organism1, organism2].sort, publication.related_organisms.sort
  end

  test 'assay association' do
    publication = FactoryBot.create(:publication)
    assay = FactoryBot.create(:assay)

    assert_not_includes publication.assays, assay

    assert_difference('Relationship.count') do
      User.with_current_user(assay.contributor.user) { publication.associate(assay) }
    end

    assert_includes publication.assays, assay
  end

  test 'publication date from pubmed' do
    mock_pubmed(content_file: 'pubmed_21533085.txt')
    result = Bio::MEDLINE.new(Bio::PubMed.efetch(21533085).first).reference
    assert_equal '2011-04-20', result.published_date.to_s

    mock_pubmed(content_file: 'pubmed_1.txt')
    result = Bio::MEDLINE.new(Bio::PubMed.efetch(1).first).reference
    assert_equal '1975-06-01', result.published_date.to_s

    mock_pubmed(content_file: 'pubmed_20533085.txt')
    result = Bio::MEDLINE.new(Bio::PubMed.efetch(20533085).first).reference
    assert_equal '2010-06-10', result.published_date.to_s
    assert_nil result.error
  end

  test 'unknown pubmed_id' do
    mock_pubmed(content_file: 'pubmed_not_found.txt')
    result = Bio::MEDLINE.new(Bio::PubMed.efetch(1111111111111).first).reference
    assert_equal 'No publication could be found on PubMed with that ID', result.error
  end

  test 'book chapter doi' do
    mock_crossref(email: 'fred@email.com', doi: '10.1007/978-3-642-16239-8_8', content_file: 'cross_ref1.xml')
    query = DOI::Query.new('fred@email.com')
    result = query.fetch('10.1007/978-3-642-16239-8_8')
    assert_equal :book_chapter, result.publication_type
    assert_equal 'Prediction with Confidence Based on a Random Forest Classifier', result.title
    assert_equal 2, result.authors.size
    assert_equal 'Artificial Intelligence Applications and Innovations 339:37-44,Springer Berlin Heidelberg', result.citation
    last_names = %w(Devetyarov Nouretdinov)
    result.authors.each do |auth|
      assert last_names.include? auth.last_name
    end

    assert_equal 'Artificial Intelligence Applications and Innovations', result.journal
    assert_equal Date.parse('1 Jan 2010'), result.date_published
    assert_equal '10.1007/978-3-642-16239-8_8', result.doi
    assert_nil result.error
  end

  test 'doi with not resolvable error' do
    mock_crossref(email: 'fred@email.com', doi: '10.4230/OASIcs.GCB.2012.1', content_file: 'cross_ref_no_resolve.xml')
    assert_raises DOI::NotFoundException do
      query = DOI::Query.new('fred@email.com')
      query.fetch('10.4230/OASIcs.GCB.2012.1')
    end
  end

  test 'malformed doi' do
    mock_crossref(email: 'fred@email.com', doi: '10.1.11.1', content_file: 'cross_ref_malformed_doi.html')
    assert_raises DOI::MalformedDOIException do
      query = DOI::Query.new('fred@email.com')
      query.fetch('10.1.11.1')
    end
  end

  test 'unsupported type doi' do
    mock_crossref(email: 'fred@email.com', doi: '10.1.11.1', content_file: 'cross_ref_unsupported_type.xml')
    assert_raises DOI::RecordNotSupported do
      query = DOI::Query.new('fred@email.com')
      query.fetch('10.1.11.1')
    end
  end

  test 'editor should not be author' do
    mock_crossref(email: 'fred@email.com', doi: '10.1371/journal.pcbi.1002352', content_file: 'cross_ref2.xml')
    query = DOI::Query.new('fred@email.com')
    result = query.fetch('10.1371/journal.pcbi.1002352')
    assert result.error.nil?, 'There should not be an error'
    assert !result.authors.collect(&:last_name).include?('Papin')
    assert_equal 5, result.authors.size
    assert_nil result.error
  end

  test 'model and datafile association' do
    publication = FactoryBot.create(:publication)

    model = FactoryBot.create(:model)
    datafile = FactoryBot.create(:data_file)

    assert_not_includes publication.models, model
    assert_not_includes publication.data_files, datafile

    assert_difference('Relationship.count', 2) do
      User.with_current_user(model.contributor.user) { publication.associate(model) }
      User.with_current_user(datafile.contributor.user) { publication.associate(datafile) }
    end

    assert_includes publication.models, model
    assert_includes publication.data_files, datafile
  end

  test 'test uuid generated' do
    publ = FactoryBot.create( :publication )
    publ.uuid = nil
    assert_nil publ.attributes['uuid']
    #publ.save(validate: false)

    publ.save
    assert_not_nil publ.attributes['uuid']
  end

  test 'title trimmed' do
    x = FactoryBot.create :publication, title: ' a pub'
    assert_equal('a pub', x.title)
  end

  test 'validation' do
    project = FactoryBot.create :project
    asset = Publication.new title: 'fred', projects: [project], doi: '10.1371/journal.pcbi.1002352', publication_type: FactoryBot.create(:journal)
    assert asset.valid?

    asset = Publication.new title: 'fred', projects: [project], pubmed_id: '111', publication_type: FactoryBot.create(:journal)
    assert asset.valid?

    asset = Publication.new title: 'fred', projects: [project], publication_type: FactoryBot.create(:journal)
    assert asset.valid?

    asset = Publication.new projects: [project], doi: '10.1371/journal.pcbi.1002352',publication_type: FactoryBot.create(:journal)
    refute asset.valid?

    # invalid DOI
    asset = Publication.new title: 'fred', doi: '10.1371', projects: [project],publication_type: FactoryBot.create(:journal)
    assert !asset.valid?
    asset = Publication.new title: 'fred', doi: 'bogus', projects: [project],publication_type: FactoryBot.create(:journal)
    assert !asset.valid?

    # invalid pubmed
    asset = Publication.new title: 'fred', pubmed_id: 0, projects: [project],publication_type: FactoryBot.create(:journal)
    assert !asset.valid?

    asset = Publication.new title: 'fred2', pubmed_id: 1234, projects: [project], publication_type: FactoryBot.create(:journal)
    assert asset.valid?

    asset = Publication.new title: 'fred', pubmed_id: 'bogus', projects: [project],publication_type: FactoryBot.create(:journal)
    assert !asset.valid?

    # can have both a pubmed and doi
    asset = Publication.new title: 'bob', doi: '10.1371/journal.pcbi.1002352', projects: [project], publication_type: FactoryBot.create(:journal)
    assert asset.valid?
    asset.pubmed_id = '999'
    assert asset.valid?
    asset.doi = nil
    assert asset.valid?
  end

  test 'creators order is returned in the order they were added' do
    p = FactoryBot.create :publication
    assert_equal 0, p.creators.size

    p1 = FactoryBot.create(:person)
    p2 = FactoryBot.create(:person)
    p3 = FactoryBot.create(:person)
    p4 = FactoryBot.create(:person)

    User.with_current_user(p.contributor) do
      [p1, p2, p3, p4].each_with_index do |author, index|
        p.publication_authors.create person_id: author.id, first_name: author.first_name, last_name: author.last_name, author_index: index
      end
      p.save!
      assert_equal 4, p.creators.size
      assert_equal [p1, p2, p3, p4], p.creators
    end
  end

  test "uuid doesn't change" do
    publ = FactoryBot.create(:publication)
    publ.save
    uuid = publ.attributes['uuid']
    publ.save
    assert_equal publ.uuid, uuid
  end

  test 'validate uniqueness of pubmed_id and doi' do
    project1 = FactoryBot.create :project
    journal = FactoryBot.create :journal
    pub = Publication.new(title: 'test1', pubmed_id: '1234', projects: [project1],publication_type_id: journal.id)
    assert pub.valid?
    assert pub.save
    pub = Publication.new(title: 'test2', pubmed_id: '1234', projects: [project1],publication_type_id: journal.id)
    assert !pub.valid?

    pub = Publication.new(title: 'test3', doi: '10.1002/0470841559.ch1', projects: [project1],publication_type_id: journal.id)
    assert pub.valid?
    assert pub.save
    pub = Publication.new(title: 'test4', doi: '10.1002/0470841559.ch1', projects: [project1],publication_type_id: journal.id)
    assert !pub.valid?

    # should be allowed for another project, but only that project on its own

    project2 = FactoryBot.create :project
    pub = Publication.new(title: 'test5', pubmed_id: '1234', projects: [project2],publication_type_id: journal.id)
    assert pub.valid?
    pub = Publication.new(title: 'test5', pubmed_id: '1234', projects: [project1, project2],publication_type_id: journal.id)
    assert !pub.valid?

    pub = Publication.new(title: 'test5', doi: '10.1002/0470841559.ch1', projects: [project2],publication_type_id: journal.id)
    assert pub.valid?
    pub = Publication.new(title: 'test5', doi: '10.1002/0470841559.ch1', projects: [project1, project2],publication_type_id: journal.id)
    assert !pub.valid?

    # make sure you can edit yourself!
    p = FactoryBot.create :publication
    User.with_current_user p.contributor do
      p.save!
      p.abstract = 'an abstract'
      assert p.valid?
      p.save!
    end
  end

  test 'validate uniqueness of title' do
    project1 = FactoryBot.create :project
    journal = FactoryBot.create :journal
    pub = Publication.new(title: 'test1', pubmed_id: '1234', projects: [project1],publication_type_id: journal.id)
    assert pub.valid?
    assert pub.save
    pub = Publication.new(title: 'test1', pubmed_id: '33343', projects: [project1],publication_type_id: journal.id)
    assert !pub.valid?

    project2 = FactoryBot.create :project
    pub = Publication.new(title: 'test1', pubmed_id: '234', projects: [project2],publication_type_id: journal.id)

    assert pub.valid?


    # make sure you can edit yourself!
    p = FactoryBot.create :publication
    User.with_current_user p.contributor do
      p.save!
      p.abstract = 'an abstract'
      assert p.valid?
      p.save!
    end
  end

  test 'strips domain from DOI if an URL is given' do
    project = FactoryBot.create(:project)
    journal = FactoryBot.create :journal
    pub = Publication.new(title: 'test1', projects: [project], doi: '10.5072/abc',publication_type_id: journal.id)
    assert pub.valid?
    assert_equal '10.5072/abc', pub.doi

    pub.doi = 'https://doi.org/10.5072/abc'
    assert pub.valid?
    assert_equal '10.5072/abc', pub.doi

    pub.doi = 'https://dx.doi.org/10.5072/abc'
    assert pub.valid?
    assert_equal '10.5072/abc', pub.doi

    pub.doi = 'http://dx.doi.org/10.5072/abc'
    assert pub.valid?
    assert_equal '10.5072/abc', pub.doi

    pub.doi = 'http://doi.org/10.5072/abc'
    assert pub.valid?
    assert_equal '10.5072/abc', pub.doi

    pub.doi = 'dx.doi.org/10.5072/abc'
    assert pub.valid?
    assert_equal '10.5072/abc', pub.doi

    pub.doi = 'www.example.com/10.5072/abc'
    refute pub.valid?
  end

  test 'has deleted contributor?' do
    item = FactoryBot.create(:publication,deleted_contributor:'Person:99')
    item.update_column(:contributor_id,nil)
    item2 = FactoryBot.create(:publication)
    item2.update_column(:contributor_id,nil)

    assert_nil item.contributor
    assert_nil item2.contributor
    refute_nil item.deleted_contributor
    assert_nil item2.deleted_contributor

    assert item.has_deleted_contributor?
    refute item2.has_deleted_contributor?
  end

  test 'has jerm contributor?' do
    item = FactoryBot.create(:publication,deleted_contributor:'Person:99')
    item.update_column(:contributor_id,nil)
    item2 = FactoryBot.create(:publication)
    item2.update_column(:contributor_id,nil)

    assert_nil item.contributor
    assert_nil item2.contributor
    refute_nil item.deleted_contributor
    assert_nil item2.deleted_contributor

    refute item.has_jerm_contributor?
    assert item2.has_jerm_contributor?
  end

  test 'related data files also includes those from assays' do
    assay = FactoryBot.create(:assay)
    assay_data_file = FactoryBot.create(:data_file, assays: [assay])
    data_file = FactoryBot.create(:data_file)
    publication = FactoryBot.create(:publication, assays: [assay], data_files: [data_file])

    assert_includes publication.related_data_files, assay_data_file
    assert_includes publication.related_data_files, data_file
  end

  test 'related models also includes those from assays' do
    assay = FactoryBot.create(:assay)
    assay_model = FactoryBot.create(:model, assays: [assay])
    model = FactoryBot.create(:model)
    publication = FactoryBot.create(:publication, assays: [assay], models: [model])

    assert_includes publication.related_models, assay_model
    assert_includes publication.related_models, model
  end
end
