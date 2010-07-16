require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:quentin)
    @object=publications(:taverna_paper_pubmed)
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

  test "should create publication" do
    assert_difference('Publication.count') do
      post :create, :publication => {:pubmed_id => 3 }
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
  end
  
  test "should create doi publication" do
    assert_difference('Publication.count') do
      post :create, :publication => {:doi => "10.1371/journal.pone.0004803" } #10.1371/journal.pone.0004803.g001 10.1093/nar/gkl320
    end

    assert_redirected_to edit_publication_path(assigns(:publication))
  end  

  test "should show publication" do
    get :show, :id => publications(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => publications(:one).to_param
    assert_response :success
  end

  test "should associate authors" do
    p = publications(:two)
    assert_equal 2, p.non_seek_authors.size
    assert_equal 0, p.creators.size
    
    seek_author = people(:quentin_person)
    
    #Associate a non-seek author to a seek person

    #Check the non_seek_authors (PublicationAuthors) decrease by 1, and the
    # seek_authors (AssetsCreators) increase by 1.
    assert_difference('PublicationAuthor.count', -1) do
      assert_difference('AssetsCreator.count', 1) do
        put :update, :id => p.id, :author => {p.non_seek_authors.first.id => seek_author.id}
      end
    end
    
    assert_redirected_to publication_path(p)
  end
  
  test "should disassociate authors" do
    p = publications(:one)
    p.creators << people(:quentin_person)
    p.creators << people(:two)
    
    assert_equal 0, p.non_seek_authors.size
    assert_equal 2, p.creators.size
    
    #Check the non_seek_authors (PublicationAuthors) increase by 2, and the
    # seek_authors (AssetsCreators) decrease by 2.
    assert_difference('PublicationAuthor.count', 2) do
      assert_difference('AssetsCreator.count', -2) do
        post :disassociate_authors, :id => p.id
      end 
    end

  end

  test "should update project" do
    p = publications(:one)
    assert p.project.nil?
    
    put :update, :id => p.id, :author => {}, :publication => {:project_id => projects(:one).id}
    
    assert_equal projects(:one), assigns(:publication).project
  end

  test "should destroy publication" do
    assert_difference('Publication.count', -1) do
      delete :destroy, :id => publications(:one).to_param
    end

    assert_redirected_to publications_path
  end
  
  test "shouldn't add paper with non-unique title" do
    #PubMed version of publication already exists, so it shouldn't re-add
    assert_no_difference('Publication.count') do
      post :create, :publication => {:doi => "10.1093/nar/gkl320" }
    end
  end
end
