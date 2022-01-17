require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include RdfTestCases
  include MockHelper

  def setup
    login_as(Factory(:admin))
  end

  def rest_api_test_object
    @object = Factory(:publication, published_date: Date.new(2013, 1, 1), publication_type: Factory(:journal))
  end

  def test_title
    get :index
    assert_select 'title', text: 'Publications', count: 1
  end

  test 'should get index' do
    Factory(:publication)
    get :index
    assert_response :success
    assert_not_nil assigns(:publications)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should not relate assays thay are not authorized for edit during create publication' do
    mock_pubmed(content_file: 'pubmed_1.txt')
    assay = assays(:metabolomics_assay)
    assert_difference('Publication.count') do

      post :create, params: { publication: { pubmed_id: 1, project_ids: [projects(:sysmo_project).id], assay_ids: [assay.id.to_s],publication_type_id: Factory(:journal).id } }

    end

    assert_redirected_to manage_publication_path(assigns(:publication), newly_created: true)
    p = assigns(:publication)
    assert_equal 0, p.assays.count
  end

  test 'should create publication' do
    mock_pubmed(content_file: 'pubmed_1.txt')
    login_as(:model_owner) # can edit assay
    assay = assays(:metabolomics_assay)
    assert_difference('Publication.count') do

      post :create, params: { publication: { pubmed_id: 1, project_ids: [projects(:sysmo_project).id], assay_ids: [assay.id.to_s],publication_type_id: Factory(:journal).id } }

    end

    assert_redirected_to manage_publication_path(assigns(:publication), newly_created: true)
    p = assigns(:publication)
    assert_equal 1, p.assays.count
    assert p.assays.include? assay
  end

  test 'should create doi publication and suggest the associated person' do
    person = people(:johan_person)
    mock_crossref(email: 'sowen@cs.man.ac.uk', doi: '10.1371/journal.pone.0004803', content_file: 'cross_ref3.xml')
    assert_difference('Publication.count') do
      post :create, params: { publication: { doi: '10.1371/journal.pone.0004803', project_ids: [projects(:sysmo_project).id],publication_type_id: Factory(:journal).id } }
    end
    get :manage, params: { id: assigns(:publication) }
    assert_response :success
    p = assigns(:publication)
    assert_equal p.publication_authors[0].suggested_person.name, person.name
    assert_nil p.publication_authors[1].suggested_person
  end


  test 'should create doi publication' do
    mock_crossref(email: 'sowen@cs.man.ac.uk', doi: '10.1371/journal.pone.0004803', content_file: 'cross_ref3.xml')
    assert_difference('Publication.count') do
      post :create, params: { publication: { doi: '10.1371/journal.pone.0004803', project_ids: [projects(:sysmo_project).id],publication_type_id: Factory(:journal).id } } # 10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_redirected_to manage_publication_path(assigns(:publication), newly_created: true)
  end


  test 'should create an inproceedings with booktitle' do
    mock_crossref(email: 'sowen@cs.man.ac.uk', doi: '10.1117/12.2275959', content_file: 'cross_ref6.xml')
    assert_difference('Publication.count') do
      post :create, params: { publication: { doi: '10.1117/12.2275959', project_ids: [projects(:sysmo_project).id],publication_type_id: Factory(:inproceedings).id } }
    end

    assert_not_nil assigns(:publication)
    assert_redirected_to manage_publication_path(assigns(:publication), newly_created: true)

  end

  test 'should create doi publication with various doi prefixes' do
    mock_crossref(email: 'sowen@cs.man.ac.uk', doi: '10.1371/journal.pone.0004803', content_file: 'cross_ref3.xml')
    assert_difference('Publication.count') do
      post :create, params: { publication: { doi: 'DOI: 10.1371/journal.pone.0004803', project_ids: [projects(:sysmo_project).id],publication_type_id: Factory(:journal).id } } # 10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_not_nil assigns(:publication)
    assert_redirected_to manage_publication_path(assigns(:publication), newly_created: true)
    assigns(:publication).destroy

    # formatted slightly different
    assert_difference('Publication.count') do
      post :create, params: { publication: { doi: 'doi:10.1371/journal.pone.0004803', project_ids: [projects(:sysmo_project).id],publication_type_id: Factory(:journal).id } } # 10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_not_nil assigns(:publication)
    assert_redirected_to manage_publication_path(assigns(:publication), newly_created: true)
    assigns(:publication).destroy

    # with url
    assert_difference('Publication.count') do
      post :create, params: { publication: { doi: 'https://doi.org/10.1371/journal.pone.0004803', project_ids: [projects(:sysmo_project).id],publication_type_id: Factory(:journal).id } } # 10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_not_nil assigns(:publication)
    assert_redirected_to manage_publication_path(assigns(:publication), newly_created: true)
    assigns(:publication).destroy

    # with url but no protocol
    assert_difference('Publication.count') do
      post :create, params: { publication: { doi: 'doi.org/10.1371/journal.pone.0004803', project_ids: [projects(:sysmo_project).id],publication_type_id: Factory(:journal).id } } # 10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_not_nil assigns(:publication)
    assert_redirected_to manage_publication_path(assigns(:publication), newly_created: true)
    assigns(:publication).destroy

    # also test with spaces around
    assert_difference('Publication.count') do
      post :create, params: { publication: { doi: '  10.1371/journal.pone.0004803  ', project_ids: [projects(:sysmo_project).id],publication_type_id: Factory(:journal).id } } # 10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_redirected_to manage_publication_path(assigns(:publication), newly_created: true)
  end

  test 'should create publication from details' do
    publication = {
      doi: '10.1371/journal.pone.0004803',
      title: 'Clickstream Data Yields High-Resolution Maps of Science',
      abstract: 'Intricate maps of science have been created from citation data to visualize the structure of scientific activity. However, most scientific publications are now accessed online. Scholarly web portals record detailed log data at a scale that exceeds the number of all existing citations combined. Such log data is recorded immediately upon publication and keeps track of the sequences of user requests (clickstreams) that are issued by a variety of users across many different domains. Given these advantages of log datasets over citation data, we investigate whether they can produce high-resolution, more current maps of science.',
      publication_authors: ['Johan Bollen', 'Herbert Van de Sompel', 'Aric Hagberg', 'Luis Bettencourt', 'Ryan Chute', 'Marko A. Rodriguez', 'Lyudmila Balakireva'],
      journal: 'Public Library of Science (PLoS)',
      published_date: Date.new(2011, 3),
      project_ids: [projects(:sysmo_project).id],
      publication_type_id: Factory(:journal).id
    }

    assert_difference('Publication.count') do
      post :create, params: { subaction: 'Create', publication: publication }
    end

    assert_redirected_to manage_publication_path(assigns(:publication))
    p = assigns(:publication)

    assert_nil p.pubmed_id
    assert_equal publication[:doi], p.doi
    assert_equal publication[:title], p.title
    assert_equal publication[:abstract], p.abstract
    assert_equal publication[:journal], p.journal
    assert_equal publication[:published_date], p.published_date
    assert_equal publication[:publication_authors], p.publication_authors.collect(&:full_name)
    assert_equal publication[:project_ids], p.projects.collect(&:id)
  end

  test 'should import from bibtex file' do
    publication = {
      title: 'Taverna: a tool for building and running workflows of services.',
      journal: 'Nucleic Acids Res',
      publication_type: Factory(:journal),
      authors: [
        PublicationAuthor.new(first_name: 'D.', last_name: 'Hull', author_index: 0),
        PublicationAuthor.new(first_name: 'K.', last_name: 'Wolstencroft', author_index: 1),
        PublicationAuthor.new(first_name: 'R.', last_name: 'Stevens', author_index: 2),
        PublicationAuthor.new(first_name: 'C.', last_name: 'Goble', author_index: 3),
        PublicationAuthor.new(first_name: 'M. R.', last_name: 'Pocock', author_index: 4),
        PublicationAuthor.new(first_name: 'P.', last_name: 'Li', author_index: 5),
        PublicationAuthor.new(first_name: 'T.', last_name: 'Oinn', author_index: 6)
      ],
      published_date: Date.new(2006)
    }
    post :create, params: { subaction: 'Import', publication: { bibtex_file: fixture_file_upload('files/publication.bibtex') } }
    p = assigns(:publication)
    assert_equal publication[:title], p.title
    assert_equal publication[:journal], p.journal
    assert_equal publication[:authors].collect(&:full_name), p.publication_authors.collect(&:full_name)
    assert_equal publication[:published_date], p.published_date
    assert_equal  publication[:publication_type].title, p.publication_type.title
  end

  test 'should import multiple from bibtex file' do

    publications = [
        {
            #publications[0]
            title: 'Taverna: a tool for building and running workflows of services.',
            journal: 'Nucleic Acids Res',
            published_date: Date.new(2006),
            publication_type: Factory(:journal),
            authors: [
                PublicationAuthor.new(first_name: 'D.', last_name: 'Hull', author_index: 0),
                PublicationAuthor.new(first_name: 'K.', last_name: 'Wolstencroft', author_index: 1),
                PublicationAuthor.new(first_name: 'R.', last_name: 'Stevens', author_index: 2),
                PublicationAuthor.new(first_name: 'C.', last_name: 'Goble', author_index: 3),
                PublicationAuthor.new(first_name: 'M. R.', last_name: 'Pocock', author_index: 4),
                PublicationAuthor.new(first_name: 'P.', last_name: 'Li', author_index: 5),
                PublicationAuthor.new(first_name: 'T.', last_name: 'Oinn', author_index: 6)
            ]
        },
        {
            #publications[1]
            title: 'Yet another tool for importing publications',
            journal: 'The second best journal',
            published_date: Date.new(2016),
            publication_type: Factory(:journal),
            authors: [
                PublicationAuthor.new(first_name: 'J.', last_name: 'Shmoe', author_index: 0),
                PublicationAuthor.new(first_name: 'M.', last_name: 'Mustermann', author_index: 1)
            ]
        },
        {
            #publications[2]
            title: 'Hydrodynamics of the Common Envelope Phase in Binary Stellar Evolution',
            published_date: Date.new(2016),
            publication_type: Factory(:phdthesis),
            authors: [
                PublicationAuthor.new(first_name: 'J.', last_name: 'Shmoe', author_index: 0),
            ]
        }

    ]

    assert_difference('Publication.count', 3) do
      post :create, params: { subaction: 'ImportMultiple', publication: { bibtex_file: fixture_file_upload('files/publications.bibtex'), project_ids: [projects(:one).id] } }
    end

    publication0 = Publication.where(title: publications[0][:title]).first
    assert_not_nil publication0
    assert_equal publications[0][:journal], publication0.journal
    assert_equal publications[0][:authors].collect(&:full_name), publication0.publication_authors.collect(&:full_name)
    assert_equal publications[0][:published_date], publication0.published_date
    assert_equal publications[0][:publication_type].title, publication0.publication_type.title
    publication1 = Publication.where(title: publications[1][:title]).first
    assert_not_nil publication1
    assert_equal publications[1][:journal], publication1.journal
    assert_equal publications[1][:authors].collect(&:full_name), publication1.publication_authors.collect(&:full_name)
    assert_equal publications[1][:published_date], publication1.published_date

    publication2 = Publication.where(title: publications[2][:title]).first
    assert_equal  publications[2][:publication_type].title, publication2.publication_type.title
  end

  test 'should only show the year for 1st Jan' do

    publication = Factory(:publication, published_date: Date.new(2013, 1, 1), publication_type: Factory(:journal))
    get :show, params: { id: publication }

    assert_response :success
    assert_select('p') do
      assert_select 'strong', text: 'Date Published:'
      assert_select 'span', text: /2013/, count: 1
      assert_select 'span', text: /Jan.* 2013/, count: 0
    end
  end

  test 'should check the correctness of bibtex files' do
    assert_difference('Publication.count', 0) do
      post :create, params: { subaction: 'ImportMultiple', publication: { bibtex_file: fixture_file_upload('files/bibtex/error_bibtex.bib'), project_ids: [projects(:one).id] } }
      assert_redirected_to publications_path
      assert_includes flash[:error], 'An InProceedings needs to have a booktitle.'
      assert_includes flash[:error], 'Please check your bibtex files, each publication should contain a title or a chapter name.'
      assert_includes flash[:error], 'An InCollection needs to have a booktitle.'
      assert_includes flash[:error], 'A Phd Thesis needs to have a school.'
      assert_includes flash[:error], 'A Masters Thesis needs to have a school.'
      assert_includes flash[:error], 'You need at least one author or editor for the Journal.'
    end
  end


  test 'should associate authors to users when importing multiple publications from bibtex files' do

    publications = [
        {
            #publications[0]
            title: 'Taverna: a tool for building and running workflows of services.',
            journal: 'Nucleic Acids Res',
            published_date: Date.new(2006),
            publication_type: Factory(:journal),
            authors: [
                PublicationAuthor.new(first_name: 'quentin', last_name: 'Jones', author_index: 0),
                PublicationAuthor.new(first_name: 'aaron', last_name: 'spiggle', author_index: 1)]
        },
        {
            #publications[1]
            title: 'This is a real publication',
            journal: 'Astronomy Astrophysics',
            published_date: Date.new(2015),
            publication_type: Factory(:journal),
            authors: [
                PublicationAuthor.new(first_name: 'Alice', last_name: 'Gräter', author_index: 0),
                PublicationAuthor.new(first_name: 'Bob', last_name: 'Mueller', author_index: 1)
            ]
        }
    ]

    assert_difference('Publication.count',2) do
      post :create, params: { subaction: 'ImportMultiple', publication: { bibtex_file: fixture_file_upload('files/bibtex/author_match.bib'), project_ids: [projects(:one).id] } }
    end


    publication = Publication.where(title: publications[0][:title]).first
    assert_not_nil publication
    publication.publication_authors.collect(&:person_id).compact.each do |person_id|
      assert_equal Person.where(id: person_id).first.last_name , PublicationAuthor.where(person_id: person_id).first.last_name
      assert_equal Person.where(id: person_id).first.first_name , PublicationAuthor.where(person_id: person_id).first.first_name
    end
    publication1 = Publication.where(title: publications[1][:title]).first
    assert_not_nil publication1
    publication1.publication_authors.collect(&:person_id).compact.each do |person_id|
      assert_not_nil person_id
    end
  end

  test 'should show old unspecified publication type' do
    publication = Factory(:publication, title: 'Publication without type')
    publication.publication_type = nil
    publication.save(validate: false)
    get :index
    assert_response :success
    assert_select '.list_item_attribute' do
      assert_select 'b', { text: 'Publication Type' }
      assert_select 'span.none_text', { text: 'Not specified' }
    end
  end

  test 'should show the publication with unspecified publication type as Not specified' do
    publication = Factory(:publication, title: 'Publication without type')
    publication.publication_type = nil
    publication.save(validate: false)
    get :show, params: { id: publication.id }
    assert_response :success
    assert_select 'p' do
      assert_select 'strong', { text: 'Publication type:' }
      assert_select 'span.none_text', { text: 'Not specified' }
    end
  end

  test 'should only show the year for 1st Jan in list view' do
    disable_authorization_checks { Publication.destroy_all }
    publication = Factory(:publication, published_date: Date.new(2013, 1, 1), title: 'blah blah blah science', publication_type: Factory(:journal))
    assert_equal 1, Publication.count
    get :index
    assert_response :success

    assert_select 'div.list_item:first-of-type' do
      assert_select 'div.list_item_title a[href=?]', publication_path(publication), text: /#{publication.title}/
      assert_select 'p.list_item_attribute', text: /2013/, count: 1
      assert_select 'p.list_item_attribute', text: /Jan.* 2013/, count: 0
    end
  end

  test 'should show publication' do
    publication = Factory :publication, contributor: User.current_user.person
    publication.save

    get :show, params: { id: publication.id }
    assert_response :success
  end

  test 'should export publication as endnote' do
    publication_formatter_mock
    with_config_value :pubmed_api_email, 'fred@email.com' do
      get :show, params: { id: publication_for_export_tests, format: 'enw' }
    end
    assert_response :success
    assert_match(/%0 Journal Article.*/, response.body)
    assert_match(/.*%A Hendrickson, W\. A\..*/, response.body)
    assert_match(/.*%A Ward, K\. B\..*/, response.body)
    assert_match(/.*%D 1975.*/, response.body)
    assert_match(/.*%T Atomic models for the polypeptide backbones of myohemerythrin and hemerythrin\..*/, response.body)
    assert_match(/.*%J Biochem Biophys Res Commun.*/, response.body)
    assert_match(/.*%V 66.*/, response.body)
    assert_match(/.*%N 4.*/, response.body)
    assert_match(/.*%P 1349-1356.*/, response.body)
    assert_match(/.*%M 5.*/, response.body)
    assert_match(/.*%U http:\/\/www.ncbi.nlm.nih.gov\/pubmed\/5.*/, response.body)
    assert_match(/.*%K Animals.*/, response.body)
    assert_match(/.*%K Cnidaria.*/, response.body)
    assert_match(/.*%K Computers.*/, response.body)
    assert_match(/.*%K \*Hemerythrin.*/, response.body)
    assert_match(/.*%K \*Metalloproteins.*/, response.body)
    assert_match(/.*%K Models, Molecular.*/, response.body)
    assert_match(/.*%K \*Muscle Proteins.*/, response.body)
    assert_match(/.*%K Protein Conformation.*/, response.body)
    assert_match(/.*%K Species Specificity.*/, response.body)
  end

  test 'should export publication as bibtex' do
    publication_formatter_mock
    with_config_value :pubmed_api_email, 'fred@email.com' do
      get :show, params: { id: publication_for_export_tests, format: 'bibtex' }
    end
    assert_response :success
    assert_match(/@article{PMID:5,.*/, response.body)
    assert_match(/.*author.*/, response.body)
    assert_match(/.*title.*/, response.body)
    assert_match(/.*journal.*/, response.body)
    assert_match(/.*year.*/, response.body)
    assert_match(/.*number.*/, response.body)
    assert_match(/.*pages.*/, response.body)
    assert_match(/.*url.*/, response.body)
  end

  test 'should export pre-print publication as bibtex' do
    publication_formatter_mock
    with_config_value :pubmed_api_email, 'fred@email.com' do
      get :show, params: { id: pre_print_publication_for_export_tests, format: 'bibtex' }
    end
    assert_response :success
    assert_match(/.*author.*/, response.body)
    assert_match(/.*title.*/, response.body)
  end

  test 'should export publication as embl' do
    publication_formatter_mock
    with_config_value :pubmed_api_email, 'fred@email.com' do
      get :show, params: { id: publication_for_export_tests, format: 'embl' }
    end
    assert_response :success
    assert_match(/RX   PUBMED; 5\..*/, response.body)
    assert_match(/.*RT   \"Atomic models for the polypeptide backbones of myohemerythrin and\nRT   hemerythrin.\";.*/, response.body)
    assert_match(/.*RA   Hendrickson W\.A\., Ward K\.B\.;.*/, response.body)
    assert_match(/.*RL   Biochem Biophys Res Commun 66\(4\):1349-1356\(1975\)\..*/, response.body)
    assert_match(/.*XX.*/, response.body)
  end

  test 'should handle bad response from efetch during export' do
    stub_request(:post, 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi')
        .with(body: { 'db' => 'pubmed', 'email' => '(fred@email.com)', 'id' => '404', 'retmode' => 'text', 'rettype' => 'medline', 'tool' => 'bioruby' },
              headers: { 'Accept' => '*/*',
                         'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                         'Content-Length' => '87',
                         'Content-Type' => 'application/x-www-form-urlencoded',
                         'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '')

    pub = Factory(:publication, title: 'A paper on blabla',
                      abstract: 'WORD ' * 20,
                      published_date: 5.days.ago.to_s(:db),
                      pubmed_id: 404,
                      publication_type: Factory(:journal))

    with_config_value :pubmed_api_email, 'fred@email.com' do
      get :show, params: { id: pub, format: 'enw' }
    end

    assert_redirected_to pub
    assert_includes flash[:error], 'There was a problem communicating with PubMed to generate the requested ENW'
  end

  test 'should handle timeout from efetch during export' do
    stub_request(:post, 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi')
        .with(body: { 'db' => 'pubmed', 'email' => '(fred@email.com)', 'id' => '999', 'retmode' => 'text', 'rettype' => 'medline', 'tool' => 'bioruby' },
              headers: { 'Accept' => '*/*',
                         'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                         'Content-Length' => '87',
                         'Content-Type' => 'application/x-www-form-urlencoded',
                         'User-Agent' => 'Ruby' })
        .to_timeout

    pub = Factory(:publication, title: 'A paper on blabla',
                  abstract: 'WORD ' * 20,
                  published_date: 5.days.ago.to_s(:db),
                  pubmed_id: 999,
                  publication_type: Factory(:journal))

    with_config_value :pubmed_api_email, 'fred@email.com' do
      get :show, params: { id: pub, format: 'enw' }
    end

    assert_redirected_to pub
    assert_includes flash[:error], 'There was a problem communicating with PubMed to generate the requested ENW'
  end

  test 'should filter publications by projects_id for export' do
    p1 = Factory(:project, title: 'OneProject')
    p2 = Factory(:project, title: 'AnotherProject')
    list_of_publ = FactoryGirl.create_list(:publication_with_author, 6)
    Factory( :max_publication, projects: [p1])
    Factory( :min_publication, projects: [p1])
    Factory( :publication, projects: [p2, p1])
    # project without publications
    get :export, params: { query: { projects_id_in: [-100] } }

    assert_response :success
    p = assigns(:publications)
    assert_equal 0, p.length
    # project with publications
    get :export, params: { query: { projects_id_in: [p1.id, p2.id] } }
    assert_response :success
    p = assigns(:publications)
    assert_equal 3, p.length
  end

  test 'should filter publications sort by published date for export' do
    FactoryGirl.create_list(:publication_with_date, 6)

    # sort by published_date asc
    get :export, params: { query: { s: [{ name: :published_date, dir: :asc }] } }
    assert_response :success
    p = assigns(:publications)
    assert_operator p[0].published_date, :<=, p[1].published_date
    assert_operator p[1].published_date, :<=, p[2].published_date

    # sort by published_date desc
    get :export, params: { query: { s: [{ name: :published_date, dir: :desc }] } }
    assert_response :success
    p = assigns(:publications)
    assert_operator p[0].published_date, :>=, p[1].published_date
    assert_operator p[1].published_date, :>=, p[2].published_date
  end

  test 'should filter publications by title contains for export' do
    FactoryGirl.create_list(:publication, 6)
    Factory(:min_publication)

    get :export, params: { query: { title_cont: 'A Minimal Publication' } }
    assert_response :success
    p = assigns(:publications)
    assert_equal 1, p.count
  end

  test 'should filter publications by author name contains for export' do
    FactoryGirl.create_list(:publication_with_author, 6)
    Factory(:max_publication)

    # sort by published_date asc
    get :export, params: { query: { publication_authors_last_name_cont: 'LastNonReg' } }
    assert_response :success
    p = assigns(:publications)
    assert_equal 1, p.count
  end

  test 'should get edit' do
    pub = Factory(:publication)
    get :edit, params: { id: pub.id }
    assert_response :success
  end


  test 'associates assay' do
    login_as(User.current_user)  # can edit assay

    publ = Factory(:publication)
    original_assay = Factory :assay, contributor: User.current_user.person, publications: [publ]
    publ.assays = [original_assay]
    refute_nil publ.contributor

    assert publ.assays.include?(original_assay)
    assert original_assay.publications.include?(publ)

    new_assay = Factory :assay, contributor: User.current_user.person
    assert new_assay.publications.empty?

    put :update, params: { id: publ, publication: { abstract: publ.abstract, assay_ids: [new_assay.id.to_s] } }

    assert_redirected_to publication_path(publ)
    publ.reload
    original_assay.reload
    new_assay.reload

    assert_equal 1, publ.assays.count

    assert !publ.assays.include?(original_assay)
    assert !original_assay.publications.include?(publ)

    assert publ.assays.include?(new_assay)
    assert new_assay.publications.include?(publ)
  end

  test 'associates data files' do
    p = Factory(:publication)
    df = Factory(:data_file, policy: Factory(:all_sysmo_viewable_policy))
    assert !p.data_files.include?(df)
    assert !df.publications.include?(p)

    login_as(p.contributor)

    assert df.can_view?
    # add association
    put :update, params: { id: p, publication: { abstract: p.abstract, data_file_ids: [df.id.to_s] } }

    assert_redirected_to publication_path(p)
    p.reload
    df.reload

    assert_equal 1, p.data_files.count

    assert p.data_files.include?(df)
    assert df.publications.include?(p)

    # remove association
    put :update, params: { id: p, publication: { abstract: p.abstract, data_file_ids: [''] } }

    assert_redirected_to publication_path(p)
    p.reload
    df.reload

    assert_equal 0, p.data_files.count
    assert_equal 0, df.publications.count
  end

  test 'associates models' do
    p = Factory(:publication)
    model = Factory(:model, policy: Factory(:all_sysmo_viewable_policy))
    assert !p.models.include?(model)
    assert !model.publications.include?(p)

    login_as(p.contributor)
    # add association
    put :update, params: { id: p, publication: { abstract: p.abstract, model_ids: [model.id.to_s] } }

    assert_redirected_to publication_path(p)
    p.reload
    model.reload

    assert_equal 1, p.models.count
    assert_equal 1, model.publications.count

    assert p.models.include?(model)
    assert model.publications.include?(p)

    # remove association
    put :update, params: { id: p, publication: { abstract: p.abstract, model_ids: [''] } }

    assert_redirected_to publication_path(p)
    p.reload
    model.reload

    assert_equal 0, p.models.count
    assert_equal 0, model.publications.count
  end

  test 'associates investigations' do
    p = Factory(:publication)
    investigation = Factory(:investigation, policy: Factory(:all_sysmo_viewable_policy))
    assert !p.investigations.include?(investigation)
    assert !investigation.publications.include?(p)

    login_as(p.contributor)
    # add association
    put :update, params: { id: p, publication: { abstract: p.abstract, investigation_ids: [investigation.id.to_s] } }

    assert_redirected_to publication_path(p)
    p.reload
    investigation.reload

    assert_equal 1, p.investigations.count

    assert p.investigations.include?(investigation)
    assert investigation.publications.include?(p)

    # remove association
    put :update, params: { id: p, publication: { abstract: p.abstract, investigation_ids: [''] } }

    assert_redirected_to publication_path(p)
    p.reload
    investigation.reload

    assert_equal 0, p.investigations.count
    assert_equal 0, investigation.publications.count
  end

  test 'associates studies' do
    p = Factory(:publication)
    study = Factory(:study, policy: Factory(:all_sysmo_viewable_policy))
    assert !p.studies.include?(study)
    assert !study.publications.include?(p)

    login_as(p.contributor)
    # add association
    put :update, params: { id: p, publication: { abstract: p.abstract, study_ids: [study.id.to_s] } }

    assert_redirected_to publication_path(p)
    p.reload
    study.reload

    assert_equal 1, p.studies.count

    assert p.studies.include?(study)
    assert study.publications.include?(p)

    # remove association
    put :update, params: { id: p, publication: { abstract: p.abstract, study_ids: [''] } }

    assert_redirected_to publication_path(p)
    p.reload
    study.reload

    assert_equal 0, p.studies.count
    assert_equal 0, study.publications.count
  end

  test 'associates presentations' do
    p = Factory(:publication)
    presentation = Factory(:presentation, policy: Factory(:all_sysmo_viewable_policy))
    assert !p.presentations.include?(presentation)
    assert !presentation.publications.include?(p)

    login_as(p.contributor)
    # add association
    put :update, params: { id: p, publication: { abstract: p.abstract, presentation_ids:[presentation.id.to_s] } }

    assert_redirected_to publication_path(p)
    p.reload
    presentation.reload

    assert_equal 1, p.presentations.count

    assert p.presentations.include?(presentation)
    assert presentation.publications.include?(p)

    # remove association
    put :update, params: { id: p, publication: { abstract: p.abstract, presentation_ids: [''] } }

    assert_redirected_to publication_path(p)
    p.reload
    presentation.reload

    assert_equal 0, p.presentations.count
    assert_equal 0, presentation.publications.count
  end

  test 'do not associate assays unauthorized for edit' do
    publ = Factory (:publication)
    original_assay = Factory(:assay)
    publ.assays = [original_assay]

    assert publ.assays.include?(original_assay)
    assert original_assay.publications.include?(publ)

    new_assay = Factory(:assay)
    assert new_assay.publications.empty?

    # Should not add the new assay and should not remove the old one
    put :update, params: { id: publ.id, publication: { abstract: publ.abstract, assay_ids: [new_assay.id] } }

    assert_redirected_to publication_path(publ)
    publ.reload
    original_assay.reload
    new_assay.reload

    assert_equal 1, publ.assays.count

    assert publ.assays.include?(original_assay)
    assert original_assay.publications.include?(publ)

    assert !publ.assays.include?(new_assay)
    assert !new_assay.publications.include?(publ)
  end

  test 'should keep model and data associations after update' do
    p = Factory(:publication_with_model_and_data_file)
    linked_model = p.models.first
    linked_data_file = p.data_files.first

    put :update, params: { id: p, publication: { abstract: p.abstract, model_ids: p.models.collect { |m| m.id.to_s },
                                       data_file_ids: p.data_files.map(&:id), assay_ids: [''] } }

    assert_redirected_to publication_path(p)
    p.reload

    assert p.assays.empty?
    assert p.models.include?(linked_model)
    assert p.data_files.include?(linked_data_file)
  end

  test 'should associate authors' do
    p = Factory(:publication, publication_authors: [Factory(:publication_author), Factory(:publication_author)])
    assert_equal 2, p.publication_authors.size
    assert_equal 0, p.creators.size

    seek_author1 = Factory(:person)
    seek_author2 = Factory(:person)

    # Associate a non-seek author to a seek person
    login_as p.contributor
    as_virtualliver do
      assert_difference('PublicationAuthor.count', 0) do
        assert_difference('AssetsCreator.count', 2) do
          put :update, params: { id: p.id, publication: {
              abstract: p.abstract,
              publication_authors_attributes: { '0' => { id: p.publication_authors[0].id, person_id: seek_author1.id },
                                                '1' => { id: p.publication_authors[1].id, person_id: seek_author2.id } } } }
        end
      end
    end
    assert_redirected_to publication_path(p)
    p.reload
  end

  test 'should associate authors_but_leave_json' do
    min_person = Factory(:min_person)
    author = Factory(:publication_author, suggested_person: min_person)
    p = Factory(:publication, publication_authors: [author], publication_type: Factory(:journal))
    assert_equal 1, p.publication_authors.size
    assert_equal 0, p.creators.size

    get :show, params: { id: p.id }, format: :json
    assert_response :success
    json = JSON.parse(@response.body)
    authors = json["data"]["attributes"]["authors"]
    matching_count = authors.count { |a| a.include? min_person.name }
    assert_equal 0, matching_count
  end

  test 'should disassociate authors' do
    mock_pubmed(content_file: 'pubmed_5.txt')
    p = Factory(:publication)
    p.publication_authors << PublicationAuthor.new(publication: p, first_name: people(:quentin_person).first_name, last_name: people(:quentin_person).last_name, person: people(:quentin_person))
    p.publication_authors << PublicationAuthor.new(publication: p, first_name: people(:aaron_person).first_name, last_name: people(:aaron_person).last_name, person: people(:aaron_person))
    p.creators << people(:quentin_person)
    p.creators << people(:aaron_person)

    assert_equal 2, p.publication_authors.size
    assert_equal 2, p.creators.size

    assert_difference('PublicationAuthor.count', 0) do
      # seek_authors (AssetsCreators) decrease by 2.
      assert_difference('AssetsCreator.count', -2) do
        post :disassociate_authors, params: { id: p.id }
      end
    end
  end

  test 'should update project' do
    publ = Factory(:publication)
    project = Factory(:min_project)
    assert_not_equal project, publ.projects.first
    put :update, params: { id: publ.id, publication: { project_ids: [project.id] } }
    assert_redirected_to publication_path(publ)
    publ.reload
    assert_equal [project], publ.projects
  end

  test 'should destroy publication' do
    publication = Factory(:publication, published_date: Date.new(2013, 6, 4))

    login_as(publication.contributor)

    assert_difference('Publication.count', -1) do
      delete :destroy, params: { id: publication.id }
    end

    assert_redirected_to publications_path
  end

  test "shouldn't add paper with non-unique title within the same project" do
    mock_crossref(email: 'sowen@cs.man.ac.uk', doi: '10.1093/nar/gkl320', content_file: 'cross_ref4.xml')
    pub = Publication.find_by_doi('10.1093/nar/gkl320')

    # PubMed version of publication already exists, so it shouldn't re-add
    assert_no_difference('Publication.count') do
      post :create, params: { publication: { doi: '10.1093/nar/gkl320', projects: pub.projects.first } } if pub
    end
  end

  test 'should retrieve the right author order after a publication is created and after some authors are associate/disassociated with seek profiles' do
    mock_crossref(email: 'sowen@cs.man.ac.uk', doi: '10.1016/j.future.2011.08.004', content_file: 'cross_ref5.xml')
    assert_difference('Publication.count') do

      post :create, params: { publication: { doi: '10.1016/j.future.2011.08.004', project_ids: [projects(:sysmo_project).id], publication_type_id: Factory(:journal).id } }

    end
    publication = assigns(:publication)
    original_authors = ['Sean Bechhofer', 'Iain Buchan', 'David De Roure', 'Paolo Missier', 'John Ainsworth', 'Jiten Bhagat', 'Philip Couch', 'Don Cruickshank',
                        'Mark Delderfield', 'Ian Dunlop', 'Matthew Gamble', 'Danius Michaelides', 'Stuart Owen', 'David Newman', 'Shoaib Sufi', 'Carole Goble']

    authors = publication.publication_authors.collect { |pa| pa.first_name + ' ' + pa.last_name } # publication_authors are ordered by author_index by default
    assert_equal original_authors, authors

    seek_author1 = Factory(:person, first_name: 'Stuart', last_name: 'Owen')
    seek_author2 = Factory(:person, first_name: 'Carole', last_name: 'Goble')

    # Associate a non-seek author to a seek person
    as_virtualliver do
      assert_difference('publication.non_seek_authors.count', -2) do
        assert_difference('AssetsCreator.count', 2) do
          put :update, params: { id: publication.id, publication: {
              abstract: publication.abstract,
              publication_authors_attributes: { '0' => { id: publication.non_seek_authors[12].id, person_id: seek_author1.id },
                                                '1' => { id: publication.non_seek_authors[15].id, person_id: seek_author2.id } } } }
        end
      end
    end

    publication.reload
    authors = publication.publication_authors.map { |pa| pa.first_name + ' ' + pa.last_name }
    assert_equal original_authors, authors

    # Disassociate seek-authors
    assert_difference('publication.non_seek_authors.count', 2) do
      assert_difference('AssetsCreator.count', -2) do
        post :disassociate_authors, params: { id: publication.id }
      end
    end

    publication.reload
    authors = publication.publication_authors.map { |pa| pa.first_name + ' ' + pa.last_name }
    assert_equal original_authors, authors
  end

  test 'should display the right author order after some authors are associate with seek-profiles' do
    doi_citation_mock
    mock_crossref(email: 'sowen@cs.man.ac.uk', doi: '10.1016/j.future.2011.08.004', content_file: 'cross_ref5.xml')
    assert_difference('Publication.count') do
      post :create, params: { publication: { doi: '10.1016/j.future.2011.08.004', project_ids: [projects(:sysmo_project).id], publication_type_id: Factory(:journal).id } } # 10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end
    assert assigns(:publication)
    publication = assigns(:publication)
    original_authors = ['Sean Bechhofer', 'Iain Buchan', 'David De Roure', 'Paolo Missier', 'John Ainsworth', 'Jiten Bhagat', 'Philip Couch', 'Don Cruickshank',
                        'Mark Delderfield', 'Ian Dunlop', 'Matthew Gamble', 'Danius Michaelides', 'Stuart Owen', 'David Newman', 'Shoaib Sufi', 'Carole Goble']

    seek_author1 = Factory(:person, first_name: 'Stuart', last_name: 'Owen')
    seek_author2 = Factory(:person, first_name: 'Carole', last_name: 'Goble')

    # seek_authors are links
    original_authors[12] = %(<a href="/people/#{seek_author1.id}">#{publication.non_seek_authors[12].first_name + ' ' + publication.non_seek_authors[12].last_name}</a>)
    original_authors[15] = %(<a href="/people/#{seek_author2.id}">#{publication.non_seek_authors[15].first_name + ' ' + publication.non_seek_authors[15].last_name}</a>)

    # Associate a non-seek author to a seek person
    assert_difference('publication.non_seek_authors.count', -2) do
      assert_difference('AssetsCreator.count', 2) do
        put :update, params: { id: publication.id, publication: {
            abstract: publication.abstract,
            publication_authors_attributes: { '0' => { id: publication.non_seek_authors[12].id, person_id: seek_author1.id },
                                              '1' => { id: publication.non_seek_authors[15].id, person_id: seek_author2.id } } } }
      end
    end
    publication.reload
    joined_original_authors = original_authors.join(', ')
    get :show, params: { id: publication.id }
    assert @response.body.include?(joined_original_authors)
  end

  test 'should avoid XSS in association forms' do
    project = Factory(:project)
    c = Factory(:person, group_memberships: [Factory(:group_membership, work_group: Factory(:work_group, project: project))])
    Factory(:event, title: '<script>alert("xss")</script> &', projects: [project], contributor: c)
    Factory(:data_file, title: '<script>alert("xss")</script> &', projects: [project], contributor: c)
    Factory(:model, title: '<script>alert("xss")</script> &', projects: [project], contributor: c)
    i = Factory(:investigation, title: '<script>alert("xss")</script> &', projects: [project], contributor: c)
    s = Factory(:study, title: '<script>alert("xss")</script> &', investigation: i, contributor: c)
    a = Factory(:assay, title: '<script>alert("xss")</script> &', study: s, contributor: c)
    pres = Factory(:presentation, title: '<script>alert("xss")</script> &', contributor: c)
    p = Factory(:publication, projects: [project], contributor: c)

    login_as(p.contributor)

    get :manage, params: { id: p.id }

    assert_response :success
    assert_not_includes response.body, '<script>alert("xss")</script>', 'Unescaped <script> tag detected'
    # This will be slow!

    # 14 = 2 * 7 (investigations, studies, assays, events, presentations, data files and models)
    # plus an extra 4 = 2 * 2 for the study optgroups in the assay and study associations
    assert_equal 18, response.body.scan('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt; &amp;').count
  end

  test 'programme publications through nested routing' do
    assert_routing 'programmes/2/publications', controller: 'publications', action: 'index', programme_id: '2'
    programme = Factory(:programme)
    publication = Factory(:publication, projects: programme.projects, policy: Factory(:public_policy),publication_type: Factory(:journal))
    publication2 = Factory(:publication, policy: Factory(:public_policy),publication_type: Factory(:journal))

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', publication_path(publication), text: publication.title
      assert_select 'a[href=?]', publication_path(publication2), text: publication2.title, count: 0
    end
  end

  test 'organism publications through nested route' do
    assert_routing 'organisms/2/publications', controller: 'publications', action: 'index', organism_id: '2'

    o1 = Factory(:organism)
    o2 = Factory(:organism)
    a1 = Factory(:assay,organisms:[o1])
    a2 = Factory(:assay,organisms:[o2])

    publication1 = Factory(:publication, assays:[a1],publication_type: Factory(:journal))
    publication2 = Factory(:publication, assays:[a2],publication_type: Factory(:journal))

    o1.reload
    assert_equal [publication1],o1.related_publications

    get :index, params: { organism_id: o1.id }


    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', publication_path(publication1), text: publication1.title
      assert_select 'a[href=?]', publication_path(publication2), text: publication2.title, count: 0
    end

  end

  test 'query single authors for typeahead' do
    FactoryGirl.create_list(:publication_with_author, 6)
    query = 'Last'
    get :query_authors_typeahead, params: { format: :json, full_name: query }
    assert_response :success
    authors = JSON.parse(@response.body)
    assert_equal 6, authors.length, authors
    assert authors[0].key?('person_id'), 'missing author person_id'
    assert authors[0].key?('first_name'), 'missing author first name'
    assert authors[0].key?('last_name'), 'missing author last name'
    assert authors[0].key?('count'), 'missing author publication count'
    assert authors[0]['first_name'].start_with?('Author')
    assert_equal 'Last', authors[0]['last_name']
    assert_nil authors[0]['person_id']
    assert_equal 1, authors[0]['count']
  end

  test 'query single author for typeahead that is unknown' do
    query = 'Nobody knows this person'
    get :query_authors_typeahead, params: { format: :json, full_name: query }
    assert_response :success
    authors = JSON.parse(@response.body)
    assert_equal 0, authors.length
  end

  test 'query authors for initialization' do
    FactoryGirl.create_list(:publication_with_author, 5)
    Factory.create(:publication_with_author, publication_authors:[Factory(:publication_author, first_name:'Existing', last_name:'Author')])
    query_authors = {
      '0' => { full_name: 'Existing Author' }, # Existing author-> should return 1
      '1' => { full_name: 'NewAuthor ShouldBeCreated' } # New author (i.e. not found)
    }
    get :query_authors, format: :json, as: :json, params: { authors: query_authors }
    assert_response :success
    authors = JSON.parse(@response.body)
    assert_equal 2, authors.length, authors
    assert authors[0].key?('person_id'), 'missing author person_id'
    assert authors[0].key?('first_name'), 'missing author first name'
    assert authors[0].key?('last_name'), 'missing author last name'
    assert authors[0].key?('count'), 'missing author publication count'
    assert_equal 'Existing', authors[0]['first_name']
    assert_equal 'Author', authors[0]['last_name']
    assert_nil authors[0]['person_id']
    assert_equal 1, authors[0]['count']

    assert authors[1].key?('person_id'), 'missing author person_id'
    assert authors[1].key?('first_name'), 'missing author first name'
    assert authors[1].key?('last_name'), 'missing author last name'
    assert authors[1].key?('count'), 'missing author publication count'
    assert_equal 'NewAuthor', authors[1]['first_name']
    assert_equal 'ShouldBeCreated', authors[1]['last_name']
    assert_nil authors[1]['person_id']
    assert_equal 0, authors[1]['count']
  end

  test 'automatically extracts DOI from full DOI url' do
    project = Factory(:project)
    journal = Factory(:journal)

    assert_difference('Publication.count') do
      post :create, params: { publication: { project_ids: ['', project.id.to_s],
                                   doi: 'https://doi.org/10.5072/abcd',
                                   title: 'Cool stuff',
                                   publication_authors: ['', User.current_user.person.name],
                                   abstract: 'We did stuff',
                                   journal: 'Journal of Interesting Stuff',
                                   published_date: '2017-05-23',
                                   publication_type_id: journal.id

                                  }, subaction: 'Create' }


    end

    assert_equal '10.5072/abcd', assigns(:publication).doi
    assert_equal journal.id, assigns(:publication).publication_type.id
  end

  def edit_max_object(pub)
    assay = Factory(:assay, policy: Factory(:public_policy))
    study = Factory(:study, policy: Factory(:public_policy))
    inv = Factory(:investigation, policy: Factory(:public_policy))
    df = Factory(:data_file, policy: Factory(:public_policy))
    model = Factory(:model, policy: Factory(:public_policy))
    pr = Factory(:presentation, policy: Factory(:public_policy))

    pub.associate(assay)
    pub.associate(study)
    pub.associate(inv)
    pub.associate(df)
    pub.associate(model)
    pub.associate(pr)
  end

  test 'should give authors permissions' do
    person = Factory(:person)
    login_as person.user
    p = Factory(:publication, contributor: person, publication_authors: [Factory(:publication_author), Factory(:publication_author)])
    seek_author1 = Factory(:person)
    seek_author2 = Factory(:person)

    assert p.can_manage?(p.contributor.user)
    refute p.can_manage?(seek_author1.user)
    refute p.can_manage?(seek_author2.user)

    assert_difference('PublicationAuthor.count', 0) do
      assert_difference('AssetsCreator.count', 2) do
        assert_difference('Permission.count', 2) do
          put :update, params: { id: p.id, publication: {
              abstract: p.abstract,
              publication_authors_attributes: { '0' => { id: p.publication_authors[0].id, person_id: seek_author1.id },
                                                '1' => { id: p.publication_authors[1].id, person_id: seek_author2.id } } } }
        end
      end
    end

    assert_redirected_to publication_path(p)

    p = assigns(:publication)
    assert p.can_manage?(p.contributor.user)
    assert p.can_manage?(seek_author1.user)
    assert p.can_manage?(seek_author2.user)
  end

  test 'should fetch pubmed preview' do
    VCR.use_cassette('publications/fairdom_by_pubmed') do
      with_config_value :pubmed_api_email, 'fred@email.com' do
        post :fetch_preview, xhr: true, params: { key: '27899646', protocol: 'pubmed', publication: { project_ids: [User.current_user.person.projects.first.id], publication_type_id: Factory(:journal).id } }
      end
    end

    assert_response :success
    assert response.body.include?('FAIRDOMHub: a repository')
  end

  test 'should handle missing pubmed preview' do
    VCR.use_cassette('publications/missing_by_pubmed') do
      with_config_value :pubmed_api_email, 'fred@email.com' do
        post :fetch_preview, xhr: true, params: { key: '40404040404', protocol: 'pubmed', publication: { project_ids: [User.current_user.person.projects.first.id], publication_type_id: Factory(:journal).id } }
      end
    end

    assert_response :internal_server_error
    assert response.body.include?('An error has occurred')
  end

  test 'should fetch doi preview' do
    VCR.use_cassette('publications/fairdom_by_doi') do
      with_config_value :pubmed_api_email, 'fred@email.com' do
        post :fetch_preview, xhr: true, params: { key: '10.1093/nar/gkw1032', protocol: 'doi', publication: { project_ids: [User.current_user.person.projects.first.id], publication_type_id: Factory(:journal).id } }
      end
    end

    assert_response :success
    assert response.body.include?('FAIRDOMHub: a repository')
  end

  test 'should handle blank pubmed' do
    VCR.use_cassette('publications/fairdom_by_doi') do
      with_config_value :pubmed_api_email, 'fred@email.com' do
        post :fetch_preview, xhr: true, params: { key: ' ', protocol: 'pubmed', publication: { project_ids: [User.current_user.person.projects.first.id], publication_type_id: Factory(:journal).id  } }
      end
    end

    assert_response :internal_server_error
    assert_match /An error has occurred.*Please enter either a DOI or a PubMed ID/,response.body
  end

  test 'should handle blank doi' do
    VCR.use_cassette('publications/fairdom_by_doi') do
      with_config_value :pubmed_api_email, 'fred@email.com' do
        post :fetch_preview, xhr: true, params: { key: ' ', protocol: 'doi', publication: { project_ids: [User.current_user.person.projects.first.id],publication_type_id: Factory(:journal).id } }
      end
    end

    assert_response :internal_server_error
    assert_match /An error has occurred.*Please enter either a DOI or a PubMed ID/,response.body
  end

  test 'should fetch doi preview with prefixes' do
    VCR.use_cassette('publications/fairdom_by_doi') do
      with_config_value :pubmed_api_email, 'fred@email.com' do
        post :fetch_preview, xhr: true, params: { key: 'doi: 10.1093/nar/gkw1032', protocol: 'doi', publication: { project_ids: [User.current_user.person.projects.first.id],publication_type_id: Factory(:journal).id } }
      end
    end

    assert_response :success
    assert response.body.include?('FAIRDOMHub: a repository')

    VCR.use_cassette('publications/fairdom_by_doi') do
      with_config_value :pubmed_api_email, 'fred@email.com' do
        post :fetch_preview, xhr: true, params: { key: 'doi.org/10.1093/nar/gkw1032', protocol: 'doi', publication: { project_ids: [User.current_user.person.projects.first.id],publication_type_id: Factory(:journal).id } }
      end
    end

    assert_response :success
    assert response.body.include?('FAIRDOMHub: a repository')

    VCR.use_cassette('publications/fairdom_by_doi') do
      with_config_value :pubmed_api_email, 'fred@email.com' do
        post :fetch_preview, xhr: true, params: { key: 'https://doi.org/10.1093/nar/gkw1032', protocol: 'doi', publication: { project_ids: [User.current_user.person.projects.first.id],publication_type_id: Factory(:journal).id } }
      end
    end

    assert_response :success
    assert response.body.include?('FAIRDOMHub: a repository')
  end

  test 'show original author name for associated person' do
    #show the original name and formatting, but with link to associated person
    registered_author = Factory(:registered_publication_author)
    person = registered_author.person
    original_full_name = registered_author.full_name
    refute_nil person

    publication = Factory(:publication, publication_authors:[registered_author, Factory(:publication_author)])
    get :show, params: { id: publication }
    assert_response :success

    assert_select "p#authors" do
      assert_select "a[href=?]", person_path(person), text: person.name, count:0
      assert_select "a[href=?]", person_path(person), text: original_full_name
    end
  end

  test 'list of investigations unique' do
    #investigation should only be listed once even if in multiple matching projects
    person = Factory(:person_in_multiple_projects)
    assert person.projects.count > 1
    investigation = Factory(:investigation,projects:person.projects,contributor:person)
    publication = Factory(:publication, contributor:person)
    login_as(person)

    get :manage, params: { id: publication }
    assert_response :success

    assert_select 'select#possible_publication_investigation_ids' do
      assert_select 'option[value=?]',investigation.id.to_s,count:1
    end
  end

  test 'manage from registration should go to manage as newly_created' do
    mock_pubmed(content_file: 'pubmed_1.txt')
    login_as(:model_owner)
    assert_difference('Publication.count') do
      post :create, params: { publication: { pubmed_id: 1, project_ids: [projects(:sysmo_project).id], publication_type_id: Factory(:journal).id } }
    end
    assert_redirected_to manage_publication_path(assigns(:publication), newly_created: true)
  end

  test 'manage from newly_created should give a delete button' do
    publication = Factory(:publication, publication_authors: [Factory(:publication_author), Factory(:publication_author)])

    login_as publication.contributor

    get :manage, params: { id: publication, newly_created: true}
    assert_response :success

    assert_select "a", { count: 1, text: "Cancel and delete" }, "This page must contain a Cancel and delete button"
  end

  test 'manage from menu should not give a delete button' do
    publication = Factory(:publication, publication_authors: [Factory(:publication_author), Factory(:publication_author)])

    login_as publication.contributor

    get :manage, params: { id: publication}
    assert_response :success

    assert_select "a", { count: 0, text: "Cancel and delete" }, "This page must not contain a Cancel and delete button"
  end



  test 'can create with valid url' do
    project = Factory(:project)

    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    publication_attrs = Factory.attributes_for(:publication,
                                                project_ids: [project.id],
                                                doi: '10.1371/journal.pone.0004803',
                                                title: 'Clickstream Data Yields High-Resolution Maps of Science',
                                                abstract: 'Intricate maps of science have been created from citation data to visualize the structure of scientific activity. However, most scientific publications are now accessed online. Scholarly web portals record detailed log data at a scale that exceeds the number of all existing citations combined. Such log data is recorded immediately upon publication and keeps track of the sequences of user requests (clickstreams) that are issued by a variety of users across many different domains. Given these advantages of log datasets over citation data, we investigate whether they can produce high-resolution, more current maps of science.',
                                                publication_authors: ['Johan Bollen', 'Herbert Van de Sompel', 'Aric Hagberg', 'Luis Bettencourt', 'Ryan Chute', 'Marko A. Rodriguez', 'Lyudmila Balakireva'],
                                                journal: 'Public Library of Science (PLoS)',
                                                published_date: Date.new(2011, 3),
                                                publication_type_id: Factory(:journal).id
    )

    assert_difference 'Publication.count' do
      post :create, params: { subaction: 'Create', publication: publication_attrs, content_blobs: [{ data_url: 'http://somewhere.com/piccy.png', data: nil }], sharing: valid_sharing }
    end

    assert_redirected_to manage_publication_path(assigns(:publication))
    p = assigns(:publication)

    #assert_nil p.pubmed_id
    assert_equal publication_attrs[:doi], p.doi
    assert_equal publication_attrs[:title], p.title
    assert_equal publication_attrs[:abstract], p.abstract
    assert_equal publication_attrs[:journal], p.journal
    assert_equal publication_attrs[:published_date], p.published_date
    assert_equal publication_attrs[:publication_authors], p.publication_authors.collect(&:full_name)
    assert_equal publication_attrs[:project_ids], p.projects.collect(&:id)

    content_blob_id = p.content_blob.id
    assert_not_nil ContentBlob.find_by_id(content_blob_id)
  end

  test 'can create with local file' do
    project = Factory(:project)

    publication_attrs = Factory.attributes_for(:publication,
                                                contributor: User.current_user,
                                                project_ids: [project.id],
                                                doi: '10.1371/journal.pone.0004803',
                                                title: 'Clickstream Data Yields High-Resolution Maps of Science - 2',
                                                abstract: 'Intricate maps of science have been created from citation data to visualize the structure of scientific activity. However, most scientific publications are now accessed online. Scholarly web portals record detailed log data at a scale that exceeds the number of all existing citations combined. Such log data is recorded immediately upon publication and keeps track of the sequences of user requests (clickstreams) that are issued by a variety of users across many different domains. Given these advantages of log datasets over citation data, we investigate whether they can produce high-resolution, more current maps of science.',
                                                publication_authors: ['Johan Bollen', 'Herbert Van de Sompel', 'Aric Hagberg', 'Luis Bettencourt', 'Ryan Chute', 'Marko A. Rodriguez', 'Lyudmila Balakireva'],
                                                journal: 'Public Library of Science (PLoS)',
                                                published_date: Date.new(2011, 3),
                                                publication_type_id: Factory(:journal).id)

    assert_difference 'ActivityLog.count' do
      assert_difference 'Publication.count' do
        assert_difference 'ContentBlob.count' do
          post :create, params: { subaction: 'Create', publication: publication_attrs, content_blobs: [{ data: file_for_upload }], sharing: valid_sharing }
        end
      end
    end

    assert_redirected_to manage_publication_path(assigns(:publication))
    p = assigns(:publication)

    assert_equal publication_attrs[:doi], p.doi
    assert_equal publication_attrs[:title], p.title
    assert_equal publication_attrs[:abstract], p.abstract
    assert_equal publication_attrs[:journal], p.journal
    assert_equal publication_attrs[:published_date], p.published_date
    assert_equal publication_attrs[:publication_authors], p.publication_authors.collect(&:full_name)
    assert_equal publication_attrs[:project_ids], p.projects.collect(&:id)

    content_blob_id = p.content_blob.id
    assert_not_nil ContentBlob.find_by_id(content_blob_id)
  end

  test 'can create publication without uploading if invalid url' do
    project = Factory(:project)

    stub_request(:head, 'http://www.blah.de/images/logo.png').to_raise(SocketError)

    publication_attrs = Factory.attributes_for(:publication,
                                       contributor: User.current_user.person,
                                       project_ids: [project.id],
                                       doi: '10.1371/journal.pone.0004803',
                                       title: 'Clickstream Data Yields High-Resolution Maps of Science - 2',
                                       abstract: 'Intricate maps of science have been created from citation data to visualize the structure of scientific activity. However, most scientific publications are now accessed online. Scholarly web portals record detailed log data at a scale that exceeds the number of all existing citations combined. Such log data is recorded immediately upon publication and keeps track of the sequences of user requests (clickstreams) that are issued by a variety of users across many different domains. Given these advantages of log datasets over citation data, we investigate whether they can produce high-resolution, more current maps of science.',
                                       publication_authors: ['Johan Bollen', 'Herbert Van de Sompel', 'Aric Hagberg', 'Luis Bettencourt', 'Ryan Chute', 'Marko A. Rodriguez', 'Lyudmila Balakireva'],
                                       journal: 'Public Library of Science (PLoS)',
                                       published_date: Date.new(2011, 3),
                                       publication_type_id: Factory(:journal).id) # .symbolize_keys(turn string key to symbol)

    assert_difference 'Publication.count' do
      assert_no_difference('ContentBlob.count') do
        post :create, params: { subaction: 'Create', publication: publication_attrs, content_blobs: [{ data_url: 'http://www.blah.de/images/logo.png' }] }
      end
    end
    assert_response :redirect
  end

  test 'cannot upload with invalid url - 2' do
    publication = Factory :publication, contributor: User.current_user.person

    login_as(publication.contributor)
    with_config_value(:allow_publications_fulltext, true) do
      assert_no_difference 'Publication.count' do
        assert_no_difference('ContentBlob.count') do
          post :upload_pdf, params: { id: publication, publication: publication, content_blobs:
            [{ data_url: 'notanurl',
               data: nil }], sharing: valid_sharing }
        end
      end
    end

    assert_response :redirect

    assert_nil publication.content_blob

  end

  test 'can upload with valid url' do
    publication = Factory :publication, contributor: User.current_user.person

    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'

    login_as(publication.contributor)
    with_config_value(:allow_publications_fulltext, true) do
      assert_no_difference 'Publication.count' do
        assert_difference('ContentBlob.count', +1) do
          post :upload_pdf, params: { id: publication, publication: publication, content_blobs:
                                                                    [{ data_url: 'http://somewhere.com/piccy.png',
                                                                       data: nil }], sharing: valid_sharing }
        end
      end
    end

    assert_response :redirect

    assert_not_nil publication.latest_version.content_blob

    content_blob_id = publication.latest_version.content_blob.id

    assert_not_nil ContentBlob.find_by_id(content_blob_id)
  end

  test 'cannot upload with invalid url' do
    publication = Factory :publication, contributor: User.current_user.person

    stub_request(:head, 'http://www.blah.de/images/logo.png').to_raise(SocketError)

    login_as(publication.contributor)
    with_config_value(:allow_publications_fulltext, true) do
      assert_no_difference 'Publication.count' do
        assert_no_difference('ContentBlob.count') do
          post :upload_pdf, params: { id: publication, publication: publication, content_blobs:
                                        [{ data_url: 'http://www.blah.de/images/logo.png',
                                                data: nil }], sharing: valid_sharing }
        end
      end
    end
    assert_response :redirect
    assert_nil publication.content_blob
  end

  test 'can upload with local file' do
    publication = Factory :publication, contributor: User.current_user.person

    login_as(publication.contributor)
    with_config_value(:allow_publications_fulltext, true) do

      assert_no_difference 'Publication.count' do
        assert_difference('ContentBlob.count', +1) do
          post :upload_pdf, params: { id: publication, publication: publication, content_blobs: [{ data: file_for_upload }],
                                  sharing: valid_sharing }
        end
      end
      assert_response :redirect

      content_blob_id = publication.latest_version.content_blob.id
      assert_not_nil ContentBlob.find_by_id(content_blob_id)
    end
  end

  test 'can soft-delete content_blob' do
    publication = Factory :max_publication, contributor: User.current_user.person

    login_as(User.current_user.person)

    with_config_value(:allow_publications_fulltext, true) do
      assert_difference('Publication::Version.count', 1) do
        assert_no_difference('Publication.count') do
          assert_no_difference('ContentBlob.count') do
            get :soft_delete_fulltext, params: {id: publication.id}
          end
        end
      end
    end

    assert_response :redirect
    # there should be a new version with empty content blob.

    assert_nil(publication.latest_version.content_blob)
  end

  test 'cannot upload with anonymous user' do
    publication = Factory :publication, policy: Factory(:public_policy, access_type: Policy::VISIBLE)

    User.current_user = nil

    with_config_value(:allow_publications_fulltext, true) do

      assert_no_difference 'Publication.count' do
        assert_no_difference'ContentBlob.count' do
          post :upload_pdf, params: { id: publication, publication: publication, content_blobs: [{ data: file_for_upload }],
                                      sharing: valid_sharing }
        end
      end
      assert_response :redirect

      assert_nil publication.content_blob
    end
  end


  test 'should create with misc link' do
    person = Factory(:person)
    login_as(person)

    project = Factory(:project)

    publication_attrs = Factory.attributes_for(:publication,
                                               contributor: User.current_user.person,
                                               project_ids: [project.id],
                                               doi: '10.1371/journal.pone.0004803',
                                               title: 'Clickstream Data Yields High-Resolution Maps of Science - 2',
                                               abstract: 'Intricate maps of science have been created from citation data to visualize the structure of scientific activity. However, most scientific publications are now accessed online. Scholarly web portals record detailed log data at a scale that exceeds the number of all existing citations combined. Such log data is recorded immediately upon publication and keeps track of the sequences of user requests (clickstreams) that are issued by a variety of users across many different domains. Given these advantages of log datasets over citation data, we investigate whether they can produce high-resolution, more current maps of science.',
                                               publication_authors: ['Johan Bollen', 'Herbert Van de Sompel', 'Aric Hagberg', 'Luis Bettencourt', 'Ryan Chute', 'Marko A. Rodriguez', 'Lyudmila Balakireva'],
                                               journal: 'Public Library of Science (PLoS)',
                                               published_date: Date.new(2011, 3),
                                               publication_type_id: Factory(:journal).id,
                                               misc_links_attributes: { '0' => { url: "http://www.slack.com/",
                                                label:'the slack about this publication' } })

    assert_difference('AssetLink.misc_link.count') do
      assert_difference('Publication.count') do
          post :create, params: { subaction: 'Create', publication: publication_attrs }
      end
    end
    publication = assigns(:publication)
    assert_equal 'http://www.slack.com/', publication.misc_links.first.url
    assert_equal 'the slack about this publication', publication.misc_links.first.label
    assert_equal AssetLink::MISC_LINKS, publication.misc_links.first.link_type
  end

  test 'should show misc link' do
    asset_link = Factory(:misc_link)
    publication = Factory(:publication, misc_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    get :show, params: { id: publication }
    assert_response :success
    assert_select 'div.panel-heading', text: /Related links/, count: 1
  end

  test 'should update publication with new misc link' do
    person = Factory(:person)
    publication = Factory(:publication, contributor: person)
    login_as(person)
    assert_nil publication.misc_links.first
    assert_difference('AssetLink.misc_link.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: publication.id, publication: { misc_links_attributes:[{ url: "http://www.slack.com/" }] }  }
      end
    end
    assert_redirected_to publication_path(publication = assigns(:publication))
    assert_equal 'http://www.slack.com/', publication.misc_links.first.url
  end

  test 'should update publication with edited misc link' do
    person = Factory(:person)
    publication = Factory(:publication, contributor: person, misc_links:[Factory(:misc_link)])
    login_as(person)
    assert_equal 1,publication.misc_links.count
    assert_no_difference('AssetLink.misc_link.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: publication.id, publication: { misc_links_attributes:[{ id:publication.misc_links.first.id, url: "http://www.wibble.com/" }] } }
      end
    end
    publication = assigns(:publication)
    assert_redirected_to publication_path(publication)
    assert_equal 1,publication.misc_links.count
    assert_equal 'http://www.wibble.com/', publication.misc_links.first.url
  end

  test 'should destroy related assetlink when the misc link is removed ' do
    person = Factory(:person)
    login_as(person)
    asset_link = Factory(:misc_link)
    publication = Factory(:publication, misc_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE), contributor: person)
    assert_difference('AssetLink.misc_link.count', -1) do
      put :update, params: { id: publication.id, publication: { misc_links_attributes:[{ id: asset_link.id, _destroy:'1' }] } }
    end
    assert_redirected_to publication_path(publication = assigns(:publication))
    assert_empty publication.misc_links
  end


  private

  def publication_for_export_tests
    Factory(:publication, title: 'A paper on blabla',
            abstract: 'WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD',
            published_date: 5.days.ago.to_s(:db),
            pubmed_id: 5,
            publication_type: Factory(:journal)

    )
  end

  def pre_print_publication_for_export_tests
    Factory(:publication, title: 'A paper on blabla',
            abstract: 'WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD WORD',
            pubmed_id: nil,
            publication_authors: [Factory(:publication_author),
                                  Factory(:publication_author)],
            publication_type: Factory(:journal)
    )
  end
end
