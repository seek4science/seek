require 'test_helper'

class SuggestedTechnologyTypesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  setup do
    login_as Factory(:user)
    @suggested_technology_type = Factory(:suggested_technology_type, :contributor_id => User.current_user.person.try(:id)).id
  end


  test "should not show manage page for normal user, but show for admins" do
    get :manage
    assert_redirected_to root_url
    logout
    login_as Factory(:user, :person_id => Factory(:admin).id)
    get :manage
    assert_response :success
  end


  test "should popup new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:suggested_technology_type)
  end

  test "should show edit own technology types" do
    get :edit, id: @suggested_technology_type
    assert_response :success
    assert_not_nil assigns(:suggested_technology_type)
  end

  test "should create" do

    assert_difference("SuggestedTechnologyType.count") do
      post :create, :suggested_technology_type => {:label => "test_technology_type", :link_from => "suggested_technology_types"}
    end
    suggested_technology_type = assigns(:suggested_technology_type)
    assert suggested_technology_type.valid?
    assert_equal 1, suggested_technology_type.parents.size
  end

  test "should update label" do
    put :update, id: @suggested_technology_type, suggested_technology_type: {:label => "child_technology_type_a"}
    assert assigns(:suggested_technology_type)
    assert_equal "child_technology_type_a", assigns(:suggested_technology_type).label
  end

  test "should update parent" do
    suggested_parent1 = Factory(:suggested_technology_type)
    suggested_parent2 = Factory(:suggested_technology_type)
    ontology_parent_uri = "http://www.mygrid.org.uk/ontology/JERMOntology#Gas_chromatography"
    ontology_parent = Factory(:suggested_technology_type).ontology_reader.class_hierarchy.hash_by_uri[ontology_parent_uri]
    suggested_technology_type = Factory(:suggested_technology_type, :contributor_id => User.current_user.person.try(:id), :parent_uri => suggested_parent1.uri)
    assert_equal 1, suggested_technology_type.parents.size
    assert_equal suggested_parent1, suggested_technology_type.parents.first
    assert_equal suggested_parent1.uri, suggested_technology_type.parent.uri.to_s

    #update to other parent suggested
    put :update, :id => suggested_technology_type.id, :suggested_technology_type => {:parent_uri => suggested_parent2.uri}
    suggested = assigns(:suggested_technology_type)
    assert suggested
    assert_equal 1, suggested.parents.size
    assert_equal suggested_parent2, suggested.parents.first
    assert_equal suggested_parent2.uri, suggested.parent.uri.to_s

    #update to other parent from ontology
    put :update, id: suggested_technology_type.id, suggested_technology_type: {:parent_uri => ontology_parent_uri}
    suggested = assigns(:suggested_technology_type)
    assert suggested
    assert_equal 1, suggested.parents.size
    assert_equal ontology_parent, suggested.parents.first
    assert_equal ontology_parent.uri.to_s, suggested.parent.uri.to_s

  end

  test "should delete suggested technology type" do
    #even owner cannot delete own type
    assert_no_difference('SuggestedTechnologyType.count') do
      delete :destroy, id: @suggested_technology_type
    end
    assert_equal "Admin rights required to manage types", flash[:error]
    flash[:error] = nil
    logout
    #log in as another user, who is not the owner of the suggested technology type
    login_as Factory(:user)
    assert_no_difference('SuggestedTechnologyType.count') do
      delete :destroy, id: @suggested_technology_type
    end

    assert_equal "Admin rights required to manage types", flash[:error]
    flash[:error] = nil
    logout

    #log in as admin
    login_as Factory(:user, :person_id => Factory(:admin).id)
    assert_difference('SuggestedTechnologyType.count', -1) do
      delete :destroy, id: @suggested_technology_type
    end
    assert_nil flash[:error]
    assert_redirected_to :action => :manage
  end

  test "should not delete technology type with child" do
    login_as Factory(:user, :person_id => Factory(:admin).id)

    parent = Factory :suggested_technology_type
    child = Factory :suggested_technology_type, :parent_uri => parent.uri

    assert_no_difference('SuggestedTechnologyType.count') do
      delete :destroy, id: parent.id
    end
    assert flash[:error]
    assert_redirected_to :action => :manage
  end

  test "should not delete technology type with assays" do
    login_as Factory(:user, :person_id => Factory(:admin).id)

    suggested = Factory :suggested_technology_type
    Factory(:experimental_assay, :technology_type_uri => suggested.uri)
    assert_no_difference('SuggestedTechnologyType.count') do
      delete :destroy, id: suggested.id
    end
    assert flash[:error]
    assert_redirected_to :action => :manage
  end

end
