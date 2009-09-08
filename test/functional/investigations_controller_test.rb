require 'test_helper'

class InvestigationsControllerTest < ActionController::TestCase
  
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:model_owner)
  end

  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:investigations)
  end

  test "should show item" do
    get :show, :id=>investigations(:metabolomics_investigation)
    assert_response :success
    assert_not_nil assigns(:investigation)
  end

  test "should show new" do
    get :new
    assert_response :success
    assert assigns(:investigation)
  end

  test "should show edit" do
    get :edit, :id=>investigations(:metabolomics_investigation)
    assert_response :success
    assert assigns(:investigation)
  end

  test "should update" do
    i=investigations(:metabolomics_investigation)
    put :update, :id=>i.id,:investigation=>{:title=>"test"}
    
    assert_redirected_to investigation_path(i)
    assert assigns(:investigation)
    assert_equal "test",assigns(:investigation).title
  end

  test "no edit button in show for person not in project" do
    login_as(:aaron)
    get :show, :id=>investigations(:metabolomics_investigation)
    assert_select "a",:text=>/Edit investigation/,:count=>0
  end

  test "edit button in show for person in project" do
    get :show, :id=>investigations(:metabolomics_investigation)
    assert_select "a",:text=>/Edit investigation/,:count=>1
  end


  test "non project member can't edit investigation" do
    login_as(:aaron)
    i=investigations(:metabolomics_investigation)
    get :edit, :id=>i
    assert_redirected_to investigation_path(i)
    assert flash[:error]
  end

  test "non project member can't update investigation" do
    login_as(:aaron)
    i=investigations(:metabolomics_investigation)
    put :update, :id=>i.id,:investigation=>{:title=>"test"}

    assert_redirected_to investigation_path(i)
    assert assigns(:investigation)
    assert flash[:error]
    assert_equal "Metabolomics Investigation",assigns(:investigation).title
  end

  test "should destroy investigation" do
    assert_difference("Investigation.count",-1) do
      delete :destroy, :id => investigations(:investigation_with_no_study).id
    end
    assert !flash[:error]
    assert_redirected_to investigations_path    
  end

  test "non project member should not destroy investigation" do
    login_as(:aaron)
    assert_no_difference("Investigation.count") do
      delete :destroy, :id => investigations(:investigation_with_no_study).id
    end
    assert flash[:error]
    assert_redirected_to investigations_path    
  end

  test "should not destroy investigation with a study" do
    assert_no_difference("Investigation.count") do
      delete :destroy, :id => investigations(:metabolomics_investigation).id
    end
    assert flash[:error]
    assert_redirected_to investigations_path    
  end

  test "option to delete investigation without study" do    
    get :show,:id=>investigations(:investigation_with_no_study).id
    assert_select "a",:text=>/Delete Investigation/,:count=>1
  end

  test "no option to delete investigation with study" do
    get :show,:id=>investigations(:metabolomics_investigation).id
    assert_select "a",:text=>/Delete Investigation/,:count=>0
  end

  test "no option to delete investigation for non project member" do
    login_as(:aaron)
    get :show,:id=>investigations(:investigation_with_no_study).id
    assert_select "a",:text=>/Delete Investigation/,:count=>0
  end

end
