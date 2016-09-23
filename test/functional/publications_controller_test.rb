require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include RdfTestCases
  include MockHelper

  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object=publications(:taverna_paper_pubmed)
    @object=publications(:taverna_paper_pubmed)
  end
  
  def test_title
    get :index
    assert_select "title",:text=>/The Sysmo SEEK Publications.*/, :count=>1
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:publications)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should not relate assays thay are not authorized for edit during create publication" do
    mock_pubmed(:content_file=>"pubmed_1.txt")
    assay=assays(:metabolomics_assay)
    assert_difference('Publication.count') do
      post :create, :publication => {:pubmed_id => 1,:project_ids=>[projects(:sysmo_project).id]},:assay_ids=>[assay.id.to_s]
      p assigns(:publication).errors.full_messages
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
    p=assigns(:publication)
    assert_equal 0,p.assays.count
  end

  test "should create publication" do
    mock_pubmed(:content_file=>"pubmed_1.txt")
    login_as(:model_owner) #can edit assay
    assay=assays(:metabolomics_assay)
    assert_difference('Publication.count') do
      post :create, :publication => {:pubmed_id => 1,:project_ids=>[projects(:sysmo_project).id] },:assay_ids=>[assay.id.to_s]
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
    p=assigns(:publication)
    assert_equal 1,p.assays.count
    assert p.assays.include? assay
  end
  
  test "should create doi publication" do
    mock_crossref(:email=>"sowen@cs.man.ac.uk",:doi=>"10.1371/journal.pone.0004803",:content_file=>"cross_ref3.xml")
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "10.1371/journal.pone.0004803", :project_ids=>[projects(:sysmo_project).id] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
  end

  test "should create doi publication with doi prefix" do
    mock_crossref(:email=>"sowen@cs.man.ac.uk",:doi=>"10.1371/journal.pone.0004803",:content_file=>"cross_ref3.xml")
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "DOI: 10.1371/journal.pone.0004803", :project_ids=>[projects(:sysmo_project).id] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_not_nil assigns(:publication)
    assert_redirected_to edit_publication_path(assigns(:publication))
    publication = assigns(:publication).destroy

    #formatted slightly different
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => " doi:10.1371/journal.pone.0004803", :project_ids=>[projects(:sysmo_project).id] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_not_nil assigns(:publication)
    assert_redirected_to edit_publication_path(assigns(:publication))
    publication = assigns(:publication).destroy

    #also test with spaces around
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "  10.1371/journal.pone.0004803  ", :project_ids=>[projects(:sysmo_project).id] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
  end

  test "should only show the year for 1st Jan" do
    publication = Factory(:publication,:published_date=>Date.new(2013,1,1))
    get :show,:id=>publication
    assert_response :success
    assert_select("p") do
      assert_select "strong", :text=>"Date Published:"
      assert_select "span", :text=>/2013/, :count=>1
      assert_select "span", :text=>/Jan.* 2013/, :count=>0
    end
  end

  test "should only show the year for 1st Jan in list view" do
    publication = Factory(:publication,:published_date=>Date.new(2013,1,1),:title=>"blah blah blah science")
    get :index
    assert_response :success
    assert_select "div.list_item:first-of-type" do
      assert_select "div.list_item_title a[href=?]",publication_path(publication),:text=>/#{publication.title}/
      assert_select "p.list_item_attribute",:text=>/2013/,:count=>1
      assert_select "p.list_item_attribute",:text=>/Jan.* 2013/,:count=>0
    end
  end

  test "should show publication" do
    get :show, :id => publications(:one)
    assert_response :success
  end

  test "should export publication as endnote" do
    publication_formatter_mock
    get :show, :id => publications(:one), :format => "enw"
    assert_response :success
    assert_match( /%0 Journal Article.*/, response.body)
    assert_match( /.*%A Hendrickson, W\. A\..*/, response.body)
    assert_match( /.*%A Ward, K\. B\..*/, response.body) 
    assert_match( /.*%D 1975.*/, response.body) 
    assert_match( /.*%T Atomic models for the polypeptide backbones of myohemerythrin and hemerythrin\..*/, response.body) 
    assert_match( /.*%J Biochem Biophys Res Commun.*/, response.body) 
    assert_match( /.*%V 66.*/, response.body) 
    assert_match( /.*%N 4.*/, response.body) 
    assert_match( /.*%P 1349-1356.*/, response.body) 
    assert_match( /.*%M 5.*/, response.body) 
    assert_match( /.*%U http:\/\/www.ncbi.nlm.nih.gov\/pubmed\/5.*/, response.body) 
    assert_match( /.*%K Animals.*/, response.body) 
    assert_match( /.*%K Cnidaria.*/, response.body) 
    assert_match( /.*%K Computers.*/, response.body) 
    assert_match( /.*%K \*Hemerythrin.*/, response.body) 
    assert_match( /.*%K \*Metalloproteins.*/, response.body) 
    assert_match( /.*%K Models, Molecular.*/, response.body) 
    assert_match( /.*%K \*Muscle Proteins.*/, response.body) 
    assert_match( /.*%K Protein Conformation.*/, response.body) 
    assert_match( /.*%K Species Specificity.*/, response.body) 
  end

  test "should export publication as bibtex" do
    publication_formatter_mock
    get :show, :id => publications(:one), :format => "bibtex"
    assert_response :success
    assert_match( /@article{PMID:5,.*/, response.body) 
    assert_match( /.*author.*/, response.body)
    assert_match( /.*title.*/, response.body)
    assert_match( /.*journal.*/, response.body)
    assert_match( /.*year.*/, response.body)
    assert_match( /.*number.*/, response.body)
    assert_match( /.*pages.*/, response.body)
    assert_match( /.*url.*/, response.body)
  end

  test "should export publication as embl" do
    publication_formatter_mock
    get :show, :id => publications(:one), :format => "embl"
    assert_response :success
    assert_match( /RX   PUBMED; 5\..*/, response.body) 
    assert_match( /.*RT   \"Atomic models for the polypeptide backbones of myohemerythrin and\nRT   hemerythrin.\";.*/, response.body)
    assert_match( /.*RA   Hendrickson W\.A\., Ward K\.B\.;.*/, response.body)
    assert_match( /.*RL   Biochem Biophys Res Commun 66\(4\):1349-1356\(1975\)\..*/, response.body)
    assert_match( /.*XX.*/, response.body)
  end

  test "should get edit" do
    get :edit, :id => publications(:one)
    assert_response :success
  end

  test "associates assay" do
    login_as(:model_owner) #can edit assay
    p = publications(:taverna_paper_pubmed)
    original_assay = assays(:assay_with_a_publication)
    assert p.assays.include?(original_assay)
    assert original_assay.publications.include?(p)

    new_assay=assays(:metabolomics_assay)
    assert new_assay.publications.empty?
    
    put :update, :id => p,:author=>{},:assay_ids=>[new_assay.id.to_s]

    assert_redirected_to publication_path(p)
    p.reload
    original_assay.reload
    new_assay.reload

    assert_equal 1, p.assays.count

    assert !p.assays.include?(original_assay)
    assert !original_assay.publications.include?(p)

    assert p.assays.include?(new_assay)
    assert new_assay.publications.include?(p)

  end

  test "associates data files" do
    p = Factory(:publication)
    df = Factory(:data_file, :policy => Factory(:all_sysmo_viewable_policy))
    assert !p.data_files.include?(df)
    assert !df.publications.include?(p)

    login_as(p.contributor)
    #add association
    put :update, :id => p,:author=>{},:data_files=>[{ id: df.id.to_s }]

    assert_redirected_to publication_path(p)
    p.reload
    df.reload

    assert_equal 1, p.data_files.count

    assert p.data_files.include?(df)
    assert df.publications.include?(p)

    #remove association
    put :update, :id => p,:author=>{},:data_file_ids=>[]

    assert_redirected_to publication_path(p)
    p.reload
    df.reload

    assert_equal 0, p.data_files.count
    assert_equal 0, df.publications.count
  end

  test "associates models" do
    p = Factory(:publication)
    model = Factory(:model, :policy => Factory(:all_sysmo_viewable_policy))
    assert !p.models.include?(model)
    assert !model.publications.include?(p)

    login_as(p.contributor)
    #add association
    put :update, :id => p,:author=>{},:model_ids=>[model.id.to_s]

    assert_redirected_to publication_path(p)
    p.reload
    model.reload

    assert_equal 1, p.models.count
    assert_equal 1, model.publications.count

    assert p.models.include?(model)
    assert model.publications.include?(p)

    #remove association
    put :update, :id => p,:author=>{},:model_ids=>[]

    assert_redirected_to publication_path(p)
    p.reload
    model.reload

    assert_equal 0, p.models.count
    assert_equal 0, model.publications.count
  end

  test "associates investigations" do
    p = Factory(:publication)
    investigation = Factory(:investigation, :policy => Factory(:all_sysmo_viewable_policy))
    assert !p.investigations.include?(investigation)
    assert !investigation.publications.include?(p)

    login_as(p.contributor)
    #add association
    put :update, :id => p,:author=>{},:investigation_ids=>["#{investigation.id.to_s}"]

    assert_redirected_to publication_path(p)
    p.reload
    investigation.reload

    assert_equal 1, p.investigations.count

    assert p.investigations.include?(investigation)
    assert investigation.publications.include?(p)

    #remove association
    put :update, :id => p,:author=>{},:investigation_ids=>[]

    assert_redirected_to publication_path(p)
    p.reload
    investigation.reload

    assert_equal 0, p.investigations.count
    assert_equal 0, investigation.publications.count
  end

  test "associates studies" do
    p = Factory(:publication)
    study = Factory(:study, :policy => Factory(:all_sysmo_viewable_policy))
    assert !p.studies.include?(study)
    assert !study.publications.include?(p)

    login_as(p.contributor)
    #add association
    put :update, :id => p,:author=>{},:study_ids=>["#{study.id.to_s}"]

    assert_redirected_to publication_path(p)
    p.reload
    study.reload

    assert_equal 1, p.studies.count

    assert p.studies.include?(study)
    assert study.publications.include?(p)

    #remove association
    put :update, :id => p,:author=>{},:study_ids=>[]

    assert_redirected_to publication_path(p)
    p.reload
    study.reload

    assert_equal 0, p.studies.count
    assert_equal 0, study.publications.count
  end
  
  test "do not associate assays unauthorized for edit" do
    p = publications(:taverna_paper_pubmed)
    original_assay = assays(:assay_with_a_publication)
    assert p.assays.include?(original_assay)
    assert original_assay.publications.include?(p)

    new_assay=assays(:metabolomics_assay)
    assert new_assay.publications.empty?

    put :update, :id => p,:author=>{},:assay_ids=>[new_assay.id.to_s]

    assert_redirected_to publication_path(p)
    p.reload
    original_assay.reload
    new_assay.reload

    assert_equal 1, p.assays.count

    assert p.assays.include?(original_assay)
    assert original_assay.publications.include?(p)

    assert !p.assays.include?(new_assay)
    assert !new_assay.publications.include?(p)

  end

  test "should keep model and data associations after update" do
    p = publications(:pubmed_2)
    put :update, :id => p,:author=>{},:assay_ids=>[],
        :data_files => p.data_files.map { |df| { id: df.id } },
        :model_ids => p.models.collect{|m| m.id.to_s}

    assert_redirected_to publication_path(p)
    p.reload

    assert p.assays.empty?
    assert p.models.include?(models(:teusink))
    assert p.data_files.include?(data_files(:picture))
  end


  test "should associate authors" do
    p = Factory(:publication, :publication_authors => [Factory.build(:publication_author), Factory.build(:publication_author)])
    assert_equal 2, p.publication_authors.size
    assert_equal 0, p.creators.size
    
    seek_author1 = people(:modeller_person)
    seek_author2 = people(:quentin_person)
    
    #Associate a non-seek author to a seek person
    login_as p.contributor
    as_virtualliver do
      assert_difference('PublicationAuthor.count', 0) do
        assert_difference('AssetsCreator.count', 2) do
          put :update, :id => p.id, :author => {p.publication_authors[1].id => seek_author2.id,p.publication_authors[0].id => seek_author1.id}
        end
      end

    end
    assert_redirected_to publication_path(p)
    p.reload
  end
  
  test "should disassociate authors" do
    mock_pubmed(:content_file=>"pubmed_5.txt")
    p = publications(:one)
    p.publication_authors << PublicationAuthor.new(:publication => p, :first_name => people(:quentin_person).first_name, :last_name => people(:quentin_person).last_name, :person => people(:quentin_person))
    p.publication_authors << PublicationAuthor.new(:publication => p, :first_name => people(:aaron_person).first_name, :last_name => people(:aaron_person).last_name, :person => people(:aaron_person))
    p.creators << people(:quentin_person)
    p.creators << people(:aaron_person)
    
    assert_equal 2, p.publication_authors.size
    assert_equal 2, p.creators.size
    
    assert_difference('PublicationAuthor.count', 0) do
      # seek_authors (AssetsCreators) decrease by 2.
      assert_difference('AssetsCreator.count', -2) do
        post :disassociate_authors, :id => p.id
      end 
    end

  end

  test "should update project" do
    p = publications(:one)
    assert_equal projects(:sysmo_project), p.projects.first
    put :update, :id => p.id, :author => {}, :publication => {:project_ids => [projects(:one).id]}
    assert_redirected_to publication_path(p)
    p.reload
    assert_equal [projects(:one)], p.projects
  end

  test "should destroy publication" do
    assert_difference('Publication.count', -1) do
      delete :destroy, :id => publications(:one).to_param
    end

    assert_redirected_to publications_path
  end
  
  test "shouldn't add paper with non-unique title within the same project" do
    mock_crossref(:email=>"sowen@cs.man.ac.uk",:doi=>"10.1093/nar/gkl320",:content_file=>"cross_ref4.xml")
    pub = Publication.find_by_doi("10.1093/nar/gkl320")

    #PubMed version of publication already exists, so it shouldn't re-add
    assert_no_difference('Publication.count') do
      post :create, :publication => {:doi => "10.1093/nar/gkl320" ,:projects=>pub.projects.first} if pub
    end
  end

  test "should retrieve the right author order after a publication is created and after some authors are associate/disassociated with seek profiles" do
    mock_crossref(:email=>"sowen@cs.man.ac.uk",:doi=>"10.1016/j.future.2011.08.004",:content_file=>"cross_ref5.xml")
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "10.1016/j.future.2011.08.004", :project_ids=>[projects(:sysmo_project).id]}
    end
    publication = assigns(:publication)
    original_authors = ["Sean Bechhofer","Iain Buchan","David De Roure","Paolo Missier","John Ainsworth","Jiten Bhagat","Philip Couch","Don Cruickshank",
                        "Mark Delderfield","Ian Dunlop","Matthew Gamble","Danius Michaelides","Stuart Owen","David Newman","Shoaib Sufi","Carole Goble"]

    authors = publication.publication_authors.collect{|pa| pa.first_name + ' ' + pa.last_name} #publication_authors are ordered by author_index by default
    assert_equal original_authors, authors

    seek_author1 = Factory(:person, :first_name => 'Stuart', :last_name => 'Owen')
    seek_author2 = Factory(:person, :first_name => 'Carole', :last_name => 'Goble')

    #Associate a non-seek author to a seek person
    as_virtualliver do
      assert_difference('publication.non_seek_authors.count', -2) do
        assert_difference('AssetsCreator.count', 2) do
          put :update, :id => publication.id, :author => {publication.non_seek_authors[12].id => seek_author1.id, publication.non_seek_authors[15].id => seek_author2.id}
        end
      end
    end

    publication.reload
    authors = publication.publication_authors.map{|pa| pa.first_name + ' ' + pa.last_name}
    assert_equal original_authors, authors

    #Disassociate seek-authors
    assert_difference('publication.non_seek_authors.count', 2) do
      assert_difference('AssetsCreator.count', -2) do
        post :disassociate_authors, :id => publication.id
      end
    end

    publication.reload
    authors =  publication.publication_authors.map{|pa| pa.first_name + ' ' + pa.last_name}
    assert_equal original_authors, authors
  end

  test "should display the right author order after some authors are associate with seek-profiles" do
    mock_crossref(:email=>"sowen@cs.man.ac.uk",:doi=>"10.1016/j.future.2011.08.004",:content_file=>"cross_ref5.xml")
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "10.1016/j.future.2011.08.004", :project_ids=>[projects(:sysmo_project).id] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end
    assert assigns(:publication)
    publication = assigns(:publication)
    original_authors = ["Sean Bechhofer","Iain Buchan","David De Roure","Paolo Missier","John Ainsworth","Jiten Bhagat","Philip Couch","Don Cruickshank",
                        "Mark Delderfield","Ian Dunlop","Matthew Gamble","Danius Michaelides","Stuart Owen","David Newman","Shoaib Sufi","Carole Goble"]



    seek_author1 = Factory(:person, :first_name => 'Stuart', :last_name => 'Owen')
    seek_author2 = Factory(:person, :first_name => 'Carole', :last_name => 'Goble')

    # seek_authors are links
    original_authors[12] = %!<a href="/people/#{seek_author1.id}">#{publication.non_seek_authors[12].first_name + " " + publication.non_seek_authors[12].last_name}</a>!
    original_authors[15] = %!<a href="/people/#{seek_author2.id}">#{publication.non_seek_authors[15].first_name + " " + publication.non_seek_authors[15].last_name}</a>!

    #Associate a non-seek author to a seek person
    assert_difference('publication.non_seek_authors.count', -2) do
      assert_difference('AssetsCreator.count', 2) do
        put :update, :id => publication.id, :author => {publication.non_seek_authors[12].id => seek_author1.id,publication.non_seek_authors[15].id => seek_author2.id}
      end
    end
    publication.reload
    joined_original_authors = original_authors.join(', ')
    get :show, :id => publication.id
    assert_equal true, @response.body.include?(joined_original_authors)


  end

  test 'should update page pagination when changing the setting from admin' do
    assert_equal 'latest', Seek::Config.default_pages[:publications]
    get :index
    assert_response :success
    assert_select ".pagination li.active" do
      assert_select "a[href=?]", publications_path(:page => 'latest')
    end

    #change the setting
    Seek::Config.default_pages[:publications] = 'all'
    get :index
    assert_response :success

    assert_select ".pagination li.active" do
      assert_select "a[href=?]", publications_path(:page => 'all')
    end
  end

  test "should avoid XSS in association forms" do
    project = Factory(:project)
    c = Factory(:person, group_memberships: [Factory(:group_membership, work_group: Factory(:work_group, project: project))])
    Factory(:event, title: '<script>alert("xss")</script> &', projects: [project], contributor: c)
    Factory(:data_file, title: '<script>alert("xss")</script> &', projects: [project], contributor: c)
    Factory(:model, title: '<script>alert("xss")</script> &', projects: [project], contributor: c)
    i = Factory(:investigation, title: '<script>alert("xss")</script> &', projects: [project], contributor: c)
    s = Factory(:study, title: '<script>alert("xss")</script> &', investigation: i, contributor: c)
    a = Factory(:assay, title: '<script>alert("xss")</script> &', study: s, contributor: c)
    p = Factory(:publication, projects: [project], contributor: c)

    login_as(p.contributor)

    get :edit, :id => p.id

    assert_response :success
    assert_not_include response.body, '<script>alert("xss")</script>', 'Unescaped <script> tag detected'
    # This will be slow!

    # 3 for events 'fancy_multiselect'
    assert_equal 3, response.body.scan('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt; &amp;').count
    # 8 = 2 each for investigations, studies, assays, models (using bespoke association forms) - datafiles loaded asynchronously
    # plus an extra 2 for the study optgroups in the assay association
    assert_equal 10, response.body.scan('\u003Cscript\u003Ealert(\"xss\")\u003C/script\u003E \u0026').count
  end

  test "programme publications through nested routing" do
    assert_routing 'programmes/2/publications', { controller: 'publications', action: 'index', programme_id: '2' }
    programme = Factory(:programme)
    publication = Factory(:publication, projects: programme.projects, policy: Factory(:public_policy))
    publication2 = Factory(:publication, policy: Factory(:public_policy))

    get :index, programme_id: programme.id

    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]", publication_path(publication), text: publication.title
      assert_select "a[href=?]", publication_path(publication2), text: publication2.title, count: 0
    end
  end

  def mock_crossref options
    url= "http://www.crossref.org/openurl/"
    params={}
    params[:format] = "unixref"
    params[:id] = "doi:"+options[:doi]
    params[:pid] = options[:email]
    params[:noredirect] = true
    url = "http://www.crossref.org/openurl/?" + params.to_param
    file=options[:content_file]
    stub_request(:get,url).to_return(:body=>File.new("#{Rails.root}/test/fixtures/files/mocking/#{file}"))

  end

  def mock_pubmed options
    url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
    file=options[:content_file]
    stub_request(:post,url).to_return(:body=>File.new("#{Rails.root}/test/fixtures/files/mocking/#{file}"))
  end
end
