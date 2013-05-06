require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  
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
    mock_pubmed(:email=>"",:id=>1,:content_file=>"pubmed_1.xml")
    assay=assays(:metabolomics_assay)
    assert_difference('Publication.count') do
      post :create, :publication => {:pubmed_id => 1,:projects=>[projects(:sysmo_project)]},:assay_ids=>[assay.id.to_s]
      p assigns(:publication).errors.full_messages
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
    p=assigns(:publication)
    assert_equal 0,p.related_assays.count
  end

  test "should create publication" do
    mock_pubmed(:email=>"",:id=>1,:content_file=>"pubmed_1.xml")
    login_as(:model_owner) #can edit assay
    assay=assays(:metabolomics_assay)
    assert_difference('Publication.count') do
      post :create, :publication => {:pubmed_id => 1,:projects=>[projects(:sysmo_project)] },:assay_ids=>[assay.id.to_s]
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
    p=assigns(:publication)
    assert_equal 1,p.related_assays.count
    assert p.related_assays.include? assay
  end
  
  test "should create doi publication" do
    mock_crossref(:email=>"sowen@cs.man.ac.uk",:doi=>"10.1371/journal.pone.0004803",:content_file=>"cross_ref3.xml")
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "10.1371/journal.pone.0004803", :projects=>[projects(:sysmo_project)] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
  end

  test "should create doi publication with doi prefix" do
    mock_crossref(:email=>"sowen@cs.man.ac.uk",:doi=>"10.1371/journal.pone.0004803",:content_file=>"cross_ref3.xml")
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "DOI: 10.1371/journal.pone.0004803", :projects=>[projects(:sysmo_project)] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_not_nil assigns(:publication)
    assert_redirected_to edit_publication_path(assigns(:publication))
    publication = assigns(:publication).destroy

    #formatted slightly different
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => " doi:10.1371/journal.pone.0004803", :projects=>[projects(:sysmo_project)] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_not_nil assigns(:publication)
    assert_redirected_to edit_publication_path(assigns(:publication))
    publication = assigns(:publication).destroy

    #also test with spaces around
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "  10.1371/journal.pone.0004803  ", :projects=>[projects(:sysmo_project)] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
  end

  test "should show publication" do
    get :show, :id => publications(:one)
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => publications(:one)
    assert_response :success
  end

  test "associates assay" do
    login_as(:model_owner) #can edit assay
    p = publications(:taverna_paper_pubmed)
    original_assay = assays(:assay_with_a_publication)
    assert p.related_assays.include?(original_assay)
    assert original_assay.related_publications.include?(p)

    new_assay=assays(:metabolomics_assay)
    assert new_assay.related_publications.empty?
    
    put :update, :id => p,:author=>{},:assay_ids=>[new_assay.id.to_s]

    assert_redirected_to publication_path(p)
    p.reload
    original_assay.reload
    new_assay.reload

    assert_equal 1, p.related_assays.count

    assert !p.related_assays.include?(original_assay)
    assert !original_assay.related_publications.include?(p)

    assert p.related_assays.include?(new_assay)
    assert new_assay.related_publications.include?(p)

  end

  test "associates data files" do
    p = Factory(:publication)
    df = Factory(:data_file, :policy => Factory(:all_sysmo_viewable_policy))
    assert !p.related_data_files.include?(df)
    assert !df.related_publications.include?(p)

    login_as(p.contributor)
    #add association
    put :update, :id => p,:author=>{},:data_file_ids=>["#{df.id.to_s},None"]

    assert_redirected_to publication_path(p)
    p.reload
    df.reload

    assert_equal 1, p.related_data_files.count

    assert p.related_data_files.include?(df)
    assert df.related_publications.include?(p)

    #remove association
    put :update, :id => p,:author=>{},:data_file_ids=>[]

    assert_redirected_to publication_path(p)
    p.reload
    df.reload

    assert_equal 0, p.related_data_files.count
    assert_equal 0, p.related_publications.count
  end

  test "associates models" do
    p = Factory(:publication)
    model = Factory(:model, :policy => Factory(:all_sysmo_viewable_policy))
    assert !p.related_models.include?(model)
    assert !model.related_publications.include?(p)

    login_as(p.contributor)
    #add association
    put :update, :id => p,:author=>{},:model_ids=>[model.id.to_s]

    assert_redirected_to publication_path(p)
    p.reload
    model.reload

    assert_equal 1, p.related_models.count
    assert_equal 1, model.related_publications.count

    assert p.related_models.include?(model)
    assert model.related_publications.include?(p)

    #remove association
    put :update, :id => p,:author=>{},:model_ids=>[]

    assert_redirected_to publication_path(p)
    p.reload
    model.reload

    assert_equal 0, p.related_models.count
    assert_equal 0, p.related_publications.count
  end

  test "do not associate assays unauthorized for edit" do
    p = publications(:taverna_paper_pubmed)
    original_assay = assays(:assay_with_a_publication)
    assert p.related_assays.include?(original_assay)
    assert original_assay.related_publications.include?(p)

    new_assay=assays(:metabolomics_assay)
    assert new_assay.related_publications.empty?

    put :update, :id => p,:author=>{},:assay_ids=>[new_assay.id.to_s]

    assert_redirected_to publication_path(p)
    p.reload
    original_assay.reload
    new_assay.reload

    assert_equal 1, p.related_assays.count

    assert p.related_assays.include?(original_assay)
    assert original_assay.related_publications.include?(p)

    assert !p.related_assays.include?(new_assay)
    assert !new_assay.related_publications.include?(p)

  end

  test "should keep model and data associations after update" do
    p = publications(:pubmed_2)
    put :update, :id => p,:author=>{},:assay_ids=>[],
        :data_file_ids => p.related_data_files.collect{|df| "#{df.id},None"},
        :model_ids => p.related_models.collect{|m| m.id.to_s}

    assert_redirected_to publication_path(p)
    p.reload

    assert p.related_assays.empty?
    assert p.related_models.include?(models(:teusink))
    assert p.related_data_files.include?(data_files(:picture))
  end


  test "should associate authors" do
    p = Factory(:publication, :publication_authors => [Factory.build(:publication_author), Factory.build(:publication_author)])
    assert_equal 2, p.publication_authors.size
    assert_equal 0, p.creators.size
    
    seek_author1 = people(:modeller_person)
    seek_author2 = people(:quentin_person)
    
    #Associate a non-seek author to a seek person
    login_as p.contributor
    assert_difference('PublicationAuthor.count', 0) do
      assert_difference('AssetsCreator.count', 2) do
        put :update, :id => p.id, :author => {p.publication_authors[1].id => seek_author2.id,p.publication_authors[0].id => seek_author1.id}
      end
    end
    
    assert_redirected_to publication_path(p)    
    p.reload
  end
  
  test "should disassociate authors" do
    mock_pubmed(:email=>"",:id=>5,:content_file=>"pubmed_5.xml", :tool => 'seek')
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
      post :create, :publication => {:doi => "10.1016/j.future.2011.08.004", :projects=>[projects(:sysmo_project)]}
    end
    publication = assigns(:publication)
    original_authors = ["Sean Bechhofer","Iain Buchan","David De Roure","Paolo Missier","John Ainsworth","Jiten Bhagat","Philip Couch","Don Cruickshank",
                        "Mark Delderfield","Ian Dunlop","Matthew Gamble","Danius Michaelides","Stuart Owen","David Newman","Shoaib Sufi","Carole Goble"]

    authors = publication.publication_authors
    assert original_authors, authors

    seek_author1 = Factory(:person, :first_name => 'Stuart', :last_name => 'Owen')
    seek_author2 = Factory(:person, :first_name => 'Carole', :last_name => 'Goble')

    #Associate a non-seek author to a seek person
    if Seek::Config.is_virtualliver
      assert_difference('publication.non_seek_authors.count', -2) do
        assert_difference('AssetsCreator.count', 2) do
          put :update, :id => publication.id, :author => {publication.non_seek_authors[12].id => seek_author1.id, publication.non_seek_authors[15].id => seek_author2.id}
        end
      end
    else
      assert_difference('PublicationAuthor.count', -2) do
        assert_difference('AssetsCreator.count', 2) do
          put :update, :id => publication.id, :author => {publication.non_seek_authors[12].id => seek_author1.id,publication.non_seek_authors[15].id => seek_author2.id}
        end
      end
    end

    publication.reload
    authors = publication.publication_authors
    assert original_authors, authors

    #Disassociate seek-authors
    assert_difference('publication.non_seek_authors.count', 2) do
      assert_difference('AssetsCreator.count', -2) do
        post :disassociate_authors, :id => publication.id
      end
    end

    publication.reload
    authors = publication.publication_authors
    assert original_authors, authors
  end

  test "should display the right author order after some authors are associate with seek-profiles" do
    mock_crossref(:email=>"sowen@cs.man.ac.uk",:doi=>"10.1016/j.future.2011.08.004",:content_file=>"cross_ref5.xml")
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "10.1016/j.future.2011.08.004", :projects=>[projects(:sysmo_project)] } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end
    publication = assigns(:publication)
    original_authors = ["Sean Bechhofer","Iain Buchan","David De Roure","Paolo Missier","John Ainsworth","Jiten Bhagat","Philip Couch","Don Cruickshank",
                        "Mark Delderfield","Ian Dunlop","Matthew Gamble","Danius Michaelides","Stuart Owen","David Newman","Shoaib Sufi","Carole Goble"]

    seek_author1 = Factory(:person, :first_name => 'Stuart', :last_name => 'Owen')
    seek_author2 = Factory(:person, :first_name => 'Carole', :last_name => 'Goble')

    #Associate a non-seek author to a seek person
    assert_difference('publication.non_seek_authors.count', -2) do
      assert_difference('AssetsCreator.count', 2) do
        put :update, :id => publication.id, :author => {publication.non_seek_authors[12].id => seek_author1.id,publication.non_seek_authors[15].id => seek_author2.id}
      end
    end

    publication.reload
    joined_original_authors = original_authors.join(', ')
    get :show, :id => publication.id
    assert_select 'p', :text => /#{joined_original_authors}/
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
    params={}
    params[:db] = "pubmed" unless params[:db]
    params[:retmode] = "xml"
    params[:id] = options[:id]
    params[:tool] = options[:tool] || "sysmo-seek"
    params[:email] = options[:email]
    url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?" + params.to_param
    file=options[:content_file]
    stub_request(:get,url).to_return(:body=>File.new("#{Rails.root}/test/fixtures/files/mocking/#{file}"))
  end
end
