require 'test_helper'

class StudiesControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:model_owner)
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:studies)
  end

  test "should get show" do
    get :show, :id=>studies(:metabolomics_study)
    assert_response :success
    assert_not_nil assigns(:study)
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:study)
  end

  test "should get edit" do
    get :edit,:id=>studies(:metabolomics_study)
    assert_response :success
    assert_not_nil assigns(:study)
  end  

  test "should update" do
    s=studies(:metabolomics_study)
    assert_not_equal "test",s.title
    put :update,:id=>s.id,:study=>{:title=>"test"}
    s=assigns(:study)
    assert_redirected_to study_path(s)
    assert_equal "test",s.title
  end

  test "should create" do
    assert_difference("Study.count") do
      post :create,:study=>{:title=>"test",:investigation=>investigations(:metabolomics_investigation)}
    end
    s=assigns(:study)
    assert_redirected_to study_path(s)
  end  

  test "should not create with assay already related to study" do
    assert_no_difference("Study.count") do
      post :create,:study=>{:title=>"test",:investigation=>investigations(:metabolomics_investigation),:assay_ids=>[assays(:metabolomics_assay3).id]}
    end
    s=assigns(:study)
    assert flash[:error]
    assert_response :redirect        
  end

  test "should not update with assay already related to study" do
    s=studies(:metabolomics_study)
    put :update,:id=>s.id,:study=>{:title=>"test",:assay_ids=>[assays(:metabolomics_assay3).id]}
    s=assigns(:study)
    assert flash[:error]
    assert_response :redirect
  end

  test "should can update with assay already related to this study" do
    s=studies(:metabolomics_study)
    put :update,:id=>s.id,:study=>{:title=>"new title",:assay_ids=>[assays(:metabolomics_assay).id]}
    s=assigns(:study)
    assert !flash[:error]
    assert_redirected_to study_path(s)
    assert_equal "new title",s.title
    assert s.assays.include?(assays(:metabolomics_assay))
  end

  test "no edit button in show for person not in project" do
    login_as(:aaron)
    get :show, :id=>studies(:metabolomics_study)
    assert_select "a",:text=>/Edit study/,:count=>0
  end

  test "edit button in show for person in project" do
    get :show, :id=>studies(:metabolomics_study)
    assert_select "a",:text=>/Edit study/,:count=>1
  end

  test "study project member can't edit" do
    login_as(:aaron)
    s=studies(:metabolomics_study)
    get :edit, :id=>s.id
    assert_redirected_to study_path(s)
    assert flash[:error]
  end

  test "study project member can't update" do
    login_as(:aaron)
    s=studies(:metabolomics_study)
    put :update, :id=>s.id,:study=>{:title=>"test"}

    assert_redirected_to study_path(s)
    assert assigns(:study)
    assert flash[:error]
    assert_equal "A Metabolomics Study",assigns(:study).title
  end

  test "study project member can delete if no assays" do
    assert_difference('Study.count',-1) do
      delete :destroy, :id => studies(:study_with_no_assays).id
    end    
    assert !flash[:error]
    assert_redirected_to studies_path
  end

  test "study non project member cannot delete even if no assays" do
    login_as(:aaron)
    assert_no_difference('Study.count') do
      delete :destroy, :id => studies(:study_with_no_assays).id
    end
    assert flash[:error]
    assert_redirected_to studies_path
  end
  
  test "study project member cannot delete if assays associated" do    
    assert_no_difference('Study.count') do
      delete :destroy, :id => studies(:metabolomics_study).id
    end
    assert flash[:error]
    assert_redirected_to studies_path
  end
  
  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> studies(:study_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end

  def test_assay_tab_doesnt_show_private_sops_or_datafiles
    login_as(:model_owner)
    assay=assays(:assay_with_public_and_private_sops_and_datafiles)
    study=studies(:study_with_assay_with_public_private_sops_and_datafile)
    get :show,:id=>study
    assert_response :success

    assert_select "div.tabbertab" do
      assert_select "h3",:text=>"Assays (1)",:count=>1
      assert_select "h3",:text=>"SOPs (1+1)",:count=>1
      assert_select "h3",:text=>"Data Files (1+1)",:count=>1
    end
    
    assert_select "div.list_item" do
      #the Assay resource_list_item
      assert_select "p.list_item_attribute a[title=?]",sops(:sop_with_fully_public_policy).title,:count=>1
      assert_select "p.list_item_attribute a[href=?]",sop_path(sops(:sop_with_fully_public_policy),:version=>1),:count=>1
      assert_select "p.list_item_attribute a[title=?]",sops(:sop_with_private_policy_and_custom_sharing).title,:count=>0
      assert_select "p.list_item_attribute a[href=?]",sop_path(sops(:sop_with_private_policy_and_custom_sharing),:version=>1),:count=>0

      assert_select "p.list_item_attribute a[title=?]",data_files(:downloadable_data_file).title,:count=>1
      assert_select "p.list_item_attribute a[href=?]",data_file_path(data_files(:downloadable_data_file),:version=>1),:count=>1
      assert_select "p.list_item_attribute a[title=?]",data_files(:private_data_file).title,:count=>0
      assert_select "p.list_item_attribute a[href=?]",data_file_path(data_files(:private_data_file),:version=>1),:count=>0      

      #the Sops and DataFiles resource_list_item
      assert_select "div.list_item_title a[href=?]",sop_path(sops(:sop_with_fully_public_policy),:version=>1),:text=>"SOP with fully public policy",:count=>1
      assert_select "div.list_item_actions a[href=?]",sop_path(sops(:sop_with_fully_public_policy),:version=>1),:count=>1
      assert_select "div.list_item_title a[href=?]",sop_path(sops(:sop_with_private_policy_and_custom_sharing),:version=>1),:count=>0
      assert_select "div.list_item_actions a[href=?]",sop_path(sops(:sop_with_private_policy_and_custom_sharing),:version=>1),:count=>0

      assert_select "div.list_item_title a[href=?]",data_file_path(data_files(:downloadable_data_file),:version=>1),:text=>"Download Only",:count=>1
      assert_select "div.list_item_actions a[href=?]",data_file_path(data_files(:downloadable_data_file),:version=>1),:count=>1
      assert_select "div.list_item_title a[href=?]",data_file_path(data_files(:private_data_file),:version=>1),:count=>0
      assert_select "div.list_item_actions a[href=?]",data_file_path(data_files(:private_data_file),:version=>1),:count=>0
    end
  end

  def test_should_show_investigation_tab
    s=studies(:metabolomics_study)
    get :show,:id=>s
    assert_response :success
    assert_select "div.tabbertab" do
      assert_select "h3",:text=>"Investigations (1)",:count=>1
    end
  end
  
  test "filtering by investigation" do
    inv=investigations(:metabolomics_investigation)
    get :index, :filter => {:investigation => inv.id}
    assert_response :success
  end

  test "filtering by project" do
    project=projects(:sysmo_project)
    get :index, :filter => {:project => project.id}
    assert_response :success
  end  
end
