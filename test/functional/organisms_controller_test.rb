require 'test_helper'

class OrganismsControllerTest < ActionController::TestCase
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases

  include RdfTestCases
  
  def setup
    login_as(:aaron)
  end

  def rest_api_test_object
    @object=Factory(:organism,:bioportal_concept=>Factory(:bioportal_concept))
  end

  test "new organism route" do
    assert_routing '/organisms/new', { controller: "organisms", action: "new" }
    assert_equal '/organisms/new', new_organism_path.to_s
  end
  
  test "admin can get edit" do
    login_as(:quentin)
    get :edit,:id=>organisms(:yeast)
    assert_response :success
    assert_nil flash[:error]
  end
  
  test "non admin cannot get edit" do
    login_as(:aaron)
    get :edit,:id=>organisms(:yeast)
    assert_response :redirect
    assert_not_nil flash[:error]
  end
  
  test "admin can update" do
    login_as(:quentin)
    y=organisms(:yeast)
    put :update,:id=>y.id,:organism=>{:title=>"fffff"}
    assert_redirected_to organism_path(y)
    assert_nil flash[:error]
    y=Organism.find(y.id)
    assert_equal "fffff",y.title
  end
  
  test "non admin cannot update" do
    login_as(:aaron)
    y=organisms(:yeast)
    put :update,:id=>y.id,:organism=>{:title=>"fffff"}
    assert_redirected_to root_path
    assert_not_nil flash[:error]
    y=Organism.find(y.id)
    assert_equal "yeast",y.title
  end
  
  test "admin can get new" do
    login_as(:quentin)
    get :new
    assert_response :success
    assert_nil flash[:error]
    assert_select 'h1',/add a new organism/i
  end

  test "project administrator can get new" do
    login_as(Factory(:project_administrator))
    get :new
    assert_response :success
    assert_nil flash[:error]
    assert_select 'h1',/add a new organism/i
  end

  test "programme administrator can get new" do
    pa = Factory(:programme_administrator_not_in_project)
    login_as(pa)

    #check not already in a project
    assert_empty pa.projects
    get :new
    assert_response :success
    assert_nil flash[:error]
    assert_select 'h1',/add a new organism/i
  end
  
  test "non admin cannot get new" do
    login_as(:aaron)
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test "admin has create organism menu option" do
    login_as(Factory(:admin))
    get :show, :id=>Factory(:organism)
    assert_response :success
    assert_select "li#create-menu" do
      assert_select "ul.dropdown-menu" do
        assert_select "li a[href=?]",new_organism_path,:text=>"Organism"
      end
    end
  end

  test "project administrator has create organism menu option" do
    login_as(Factory(:project_administrator))
    get :show, :id=>Factory(:organism)
    assert_response :success
    assert_select "li#create-menu" do
      assert_select "ul.dropdown-menu" do
        assert_select "li a[href=?]",new_organism_path,:text=>"Organism"
      end
    end
  end

  test "non admin doesn not have create organism menu option" do
    login_as(Factory(:user))
    get :show, :id=>Factory(:organism)
    assert_response :success
    assert_select "li#create-menu" do
      assert_select "ul.dropdown-menu" do
        assert_select "li a[href=?]",new_organism_path,:text=>"Organism",:count=>0
      end
    end
  end
  
  test "admin can create new organism" do
    login_as(:quentin)
    assert_difference("Organism.count") do
      post :create, :organism=>{:title=>"An organism"}
    end
    assert_not_nil assigns(:organism)
    assert_redirected_to organism_path(assigns(:organism))
  end

  test "project administrator can create new organism" do
    login_as(Factory(:project_administrator))
    assert_difference("Organism.count") do
      post :create, :organism=>{:title=>"An organism"}
    end
    assert_not_nil assigns(:organism)
    assert_redirected_to organism_path(assigns(:organism))
  end

  test "programme administrator can create new organism" do
    login_as(Factory(:programme_administrator_not_in_project))
    assert_difference("Organism.count") do
      post :create, :organism=>{:title=>"An organism"}
    end
    assert_not_nil assigns(:organism)
    assert_redirected_to organism_path(assigns(:organism))
  end


  
  test "non admin cannot create new organism" do
    login_as(:aaron)
    assert_no_difference("Organism.count") do
      post :create, :organism=>{:title=>"An organism"}
    end    
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end
  
  test "delete button disabled for associated organisms" do
    login_as(:quentin)
    y=organisms(:yeast)
    get :show,:id=>y
    assert_response :success
    assert_select "span.disabled_icon img",:count=>1
    assert_select "span.disabled_icon a",:count=>0
  end
  
  test "admin sees edit and create buttons" do
    login_as(:quentin)
    y=organisms(:human)
    get :show,:id=>y
    assert_response :success
    assert_select "#content a[href=?]",edit_organism_path(y),:count=>1
    assert_select "#content a",:text=>/Edit Organism/,:count=>1
    
    assert_select "#content a[href=?]",new_organism_path,:count=>1
    assert_select "#content a",:text=>/Add Organism/,:count=>1
        
    assert_select "#content a",:text=>/Delete Organism/,:count=>1
  end

  test "project administrator sees create buttons" do
    login_as(Factory(:project_administrator))
    y=organisms(:human)
    get :show,:id=>y
    assert_response :success

    assert_select "#content a[href=?]",new_organism_path,:count=>1
    assert_select "#content a",:text=>/Add Organism/,:count=>1

  end
  
  test "non admin does not see edit, create and delete buttons" do
    login_as(:aaron)
    y=organisms(:human)
    get :show,:id=>y
    assert_response :success
    assert_select "#content a[href=?]",edit_organism_path(y),:count=>0
    assert_select "#content a",:text=>/Edit Organism/,:count=>0
    
    assert_select "#content a[href=?]",new_organism_path,:count=>0
    assert_select "#content a",:text=>/Add Organism/,:count=>0
    
    assert_select "#content a",:text=>/Delete Organism/,:count=>0
  end
  
  test "delete as admin" do
    login_as(:quentin)
    o=organisms(:human)
    assert_difference('Organism.count', -1) do
      delete :destroy, :id => o
    end
    assert_redirected_to organisms_path
  end

  test "delete as project administrator" do
    login_as(Factory(:project_administrator))
    o=organisms(:human)
    assert_difference('Organism.count', -1) do
      delete :destroy, :id => o
    end
    assert_redirected_to organisms_path
  end
  
  test "cannot delete as non-admin" do
    login_as(:aaron)
    o=organisms(:human)
    assert_no_difference('Organism.count') do
      delete :destroy, :id => o
    end
    refute_nil flash[:error]
  end

  test "visualise available when logged out" do
    logout
    o=Factory(:organism,:bioportal_concept=>Factory(:bioportal_concept))
    get :visualise, :id=>o
    assert_response :success
  end
  
  test "cannot delete associated organism" do
    login_as(:quentin)
    o=organisms(:yeast)
    assert_no_difference('Organism.count') do
      delete :destroy, :id => o
    end    
  end

  test "should list strains" do
    user = Factory :user
    login_as(user)
    organism = Factory :organism
    strain_a=Factory :strain,:title=>"strainA",:organism=>organism
    parent_strain=Factory :strain
    strain_b=Factory :strain,:title=>"strainB",:parent=>parent_strain,:organism=>organism


    get :show,:id=>organism
    assert_response :success
    assert_select "table.strain_list" do
      assert_select "tr",:count=>2 do
        assert_select "td > a[href=?]",strain_path(strain_a),:text=>strain_a.title
        assert_select "td > a[href=?]",strain_path(strain_b),:text=>strain_b.title
        assert_select "td > a[href=?]",strain_path(parent_strain),:text=>parent_strain.title
      end
    end
  end

  test "strains cleaned up when organism deleted" do
    login_as(:quentin)
    organism = Factory(:organism)
    strains = FactoryGirl.create_list(:strain, 3, organism: organism, contributor: nil)

    assert_difference('Organism.count', -1) do
      assert_difference('Strain.count', -3) do
        delete :destroy, :id => organism
      end
    end
  end
  
end
