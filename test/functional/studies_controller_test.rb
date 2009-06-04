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

  test "edit should not show associated assays" do
    get :edit, :id=>studies(:metabolomics_study)
    assert_response :success
    assert_select "select#possible_assays" do
      assert_select "option",:text=>/Assay with no Study/,:count=>1
      assert_select "option",:text=>/Metabolomics Assay2/,:count=>0
    end
  end

  test "new should not show associated assays" do
    get :new
    assert_response :success
    assert_select "select#possible_assays" do
      assert_select "option",:text=>/Assay with no Study/,:count=>1
      assert_select "option",:text=>/Metabolomics Assay2/,:count=>0
    end
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

  test "should create with assay" do
    assert_difference("Study.count") do
      post :create,:study=>{:title=>"test",:investigation=>investigations(:metabolomics_investigation),:assay_ids=>[assays(:assay_with_no_study).id]}
    end
    s=assigns(:study)
    assert_redirected_to study_path(s)
    assert_equal 1,s.assays.size
    assert s.assays.include?(assays(:assay_with_no_study))
    assert !flash[:error]
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
  
end
