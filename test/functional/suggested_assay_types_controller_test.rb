require 'test_helper'

class SuggestedAssayTypesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    login_as Factory(:user)
  end

  test "should not show manage page for normal user, but show for admins" do
    get :manage
    assert_redirected_to root_url

    logout
    login_as Factory(:user, :person_id => Factory(:admin).id)
    get :manage
    assert_response :success
  end

  test "should new" do
    suggested = Factory(:suggested_assay_type,:ontology_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics")
    suggested2 = Factory(:suggested_assay_type, :parent_id=>suggested.id)
    get :new
    assert_response :success
  end

  test "should new with ajax" do
    xhr :get, "new"
    assert_response :success
  end

  test "should show edit own assay types" do
    get :edit, id: Factory(:suggested_assay_type, :contributor_id => User.current_user.person.try(:id)).id
    assert_response :success
    assert_not_nil assigns(:suggested_assay_type)
  end

  test "should edit with ajax" do
    xhr :get, "edit", id: Factory(:suggested_assay_type, :contributor_id => User.current_user.person.try(:id)).id
    assert_response :success
  end

  test "should create with suggested parent" do
    login_as Factory(:admin)
    suggested = Factory(:suggested_assay_type,:ontology_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics")
    assert suggested.children.empty?
    assert_difference("SuggestedAssayType.count") do
      post :create, :suggested_assay_type => {:label => "test assay type",:parent_uri=>"suggested_assay_type:#{suggested.id}"}
    end
    assert_redirected_to :action => :manage
    assert suggested.children.count==1
    get :manage
    assert_select "li a", :text => /test assay type/
  end

  test "should create with ontology parent" do
    login_as Factory(:admin)

    assert_difference("SuggestedAssayType.count") do
      post :create, :suggested_assay_type => {:label => "test assay type",:parent_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"}
    end
    assert_redirected_to :action => :manage
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",SuggestedAssayType.last.parent.uri
    get :manage
    assert_select "li a", :text => /test assay type/
  end

  test "should create for ajax request" do
    assert_difference("SuggestedAssayType.count") do
      xhr :post, :create, :suggested_assay_type => {:label => "test_assay_type",:parent_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"}
    end
    assert_select "select option[selected='selected']", :text => /test_assay_type/
  end

  test "should update for ajax request" do
    suggested_assay_type = Factory(:suggested_assay_type, :contributor_id => User.current_user.person.try(:id))
    xhr :put, :update, id: suggested_assay_type.id, suggested_assay_type: {:label => "child_assay_type_a"}
    assert_select "select option[value=?][selected='selected']", suggested_assay_type.uri, :text => /child_assay_type_a/
  end

  test "should update label" do
    login_as Factory(:admin)
    suggested_assay_type = Factory(:suggested_assay_type, :label => "old label", :contributor_id => User.current_user.person.try(:id))
    put :update, id: suggested_assay_type.id, suggested_assay_type: {:label => "new label"}
    assert_redirected_to :action => :manage
    get :manage
    assert_select "li a[href=?]", http_escape(assay_types_path(uri: suggested_assay_type.uri, label: "new label")), :text => /new label/
  end

  test "should update parent" do
    login_as Factory(:admin)

    suggested_parent1 = Factory(:suggested_assay_type)
    suggested_parent2 = Factory(:suggested_assay_type)
    ontology_parent_uri = "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"

    suggested_assay_type = Factory(:suggested_assay_type, :contributor_id => User.current_user.person.try(:id), :parent_id => suggested_parent1.id)
    assert_equal 1, suggested_assay_type.parents.size
    assert_equal suggested_parent1, suggested_assay_type.parents.first
    assert_equal suggested_parent1.uri, suggested_assay_type.parent.uri.to_s

    #update to other parent suggested
    put :update, :id => suggested_assay_type.id, :suggested_assay_type => {:parent_uri => "suggested_assay_type:#{suggested_parent2.id}"}
    assert_redirected_to :action => :manage
    suggested_parent2.reload
    assert_include suggested_parent2.children,suggested_assay_type

    #update to other parent from ontology
    put :update, id: suggested_assay_type.id, suggested_assay_type: {:parent_uri => ontology_parent_uri}
    assert_redirected_to :action => :manage

    ontology_parent = Seek::Ontologies::AssayTypeReader.instance.class_for_uri("http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics")
    assert ontology_parent.children.include?(suggested_assay_type)

  end


  test "should delete assay" do
    #even owner cannot delete own type
    suggested_assay_type = Factory(:suggested_assay_type, :label => "delete_me", :contributor_id => User.current_user.person.try(:id))
    assert_no_difference('SuggestedAssayType.count') do
      delete :destroy, id: suggested_assay_type.id
    end
    assert_equal "Admin rights required to manage types", flash[:error]
    flash[:error] = nil
    logout
    #log in as another user, who is not the owner of the suggested assay type
    login_as Factory(:user)
    assert_no_difference('SuggestedAssayType.count') do
      delete :destroy, id: suggested_assay_type.id
    end

    assert_equal "Admin rights required to manage types", flash[:error]
    flash[:error] = nil
    logout

    #log in as admin
    login_as Factory(:user, :person_id => Factory(:admin).id)
    assert_difference('SuggestedAssayType.count', -1) do
      delete :destroy, id: suggested_assay_type.id
    end
    assert_nil flash[:error]
    assert_redirected_to :action => :manage
  end

  test "should not delete assay_type with child" do
    login_as Factory(:user, :person_id => Factory(:admin).id)

    parent = Factory :suggested_assay_type
    child = Factory :suggested_assay_type, :parent_id => parent.id

    assert_no_difference('SuggestedAssayType.count') do
      delete :destroy, id: parent.id
    end
    assert flash[:error]
    assert_redirected_to :action => :manage
  end

  test "should not delete assay_type with assays" do
    login_as Factory(:user, :person_id => Factory(:admin).id)

    suggested_at = Factory :suggested_assay_type
    Factory(:experimental_assay, :suggested_assay_type => suggested_at)
    assert_no_difference('SuggestedAssayType.count') do
      delete :destroy, id: suggested_at.id
    end
    assert flash[:error]
    assert_redirected_to :action => :manage
  end

  private

  def http_escape url
    ERB::Util.html_escape url
  end

end
