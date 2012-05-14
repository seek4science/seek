require "test_helper"

class SpecimensControllerTest < ActionController::TestCase

fixtures :all
  include AuthenticatedTestHelper
  include RestTestCases

  def setup
    login_as :owner_of_fully_public_policy
    @object = Factory(:specimen, :contributor => User.current_user,
            :title => "test1",
            :policy => policies(:policy_for_viewable_data_file))
  end

  test "index xml validates with schema" do
    Factory(:specimen, :contributor => User.current_user,
            :title => "test2",
            :policy => policies(:policy_for_viewable_data_file))
    Factory :specimen, :policy => policies(:editing_for_all_sysmo_users_policy)
    get :index, :format =>"xml"
    assert_response :success
    assert_not_nil assigns(:specimens)

    validate_xml_against_schema(@response.body)

  end

  test "show xml validates with schema" do
    s =Factory(:specimen, :contributor => User.current_user,
               :title => "test2",
               :policy => policies(:policy_for_viewable_data_file))
    get :show, :id => s, :format =>"xml"
    assert_response :success
    assert_not_nil assigns(:specimen)

    validate_xml_against_schema(@response.body)
  end
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:specimens)
  end
  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:specimen)

  end
  test "should create" do
    assert_difference("Specimen.count") do
      post :create, :specimen => {:title => "running mouse NO.1",
                                  :organism_id=>Factory(:organism).id,
                                  :lab_internal_number =>"Do232",
                                  :contributor => Factory(:user),
                                  :institution => Factory(:institution),
                                  :strain => Factory(:strain),
                                  :project_ids => [Factory(:project).id]}

    end
    s = assigns(:specimen)
    assert_redirected_to specimen_path(s)
    assert_equal "running mouse NO.1", s.title
  end
  test "should get show" do
    get :show, :id => Factory(:specimen,
                              :title=>"running mouse NO2",
                              :policy =>policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_not_nil assigns(:specimen)
  end

  test "should get edit" do
    get :edit, :id=> Factory(:specimen, :policy => policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_not_nil assigns(:specimen)
  end
  test "should update" do
    specimen = Factory(:specimen, :title=>"Running mouse NO3", :policy =>policies(:editing_for_all_sysmo_users_policy))
    creator1= Factory(:person,:last_name =>"test1")
    creator2 = Factory(:person,:last_name =>"test2")
    assert_not_equal "test", specimen.title
    put :update, :id=>specimen.id, :specimen =>{:title =>"test",:project_ids => [Factory(:project).id]},
        :creators => [[creator1.name,creator1.id],[creator2.name,creator2.id]].to_json
    s = assigns(:specimen)
    assert_redirected_to specimen_path(s)
    assert_equal "test", s.title
  end

  test "should destroy" do
    s = Factory :specimen, :contributor => User.current_user
    assert_difference("Specimen.count", -1, "A specimen should be deleted") do
      delete :destroy, :id => s.id
    end
  end
  test "unauthorized users cannot add new specimens" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    get :new
    assert_response :redirect
  end
  test "unauthorized user cannot edit specimen" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :specimen, :policy => Factory(:private_policy)
    get :edit, :id =>s.id
    assert_redirected_to specimen_path(s)
    assert flash[:error]
  end
  test "unauthorized user cannot update specimen" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :specimen, :policy => Factory(:private_policy)

    put :update, :id=> s.id, :specimen =>{:title =>"test"}
    assert_redirected_to specimen_path(s)
    assert flash[:error]
  end

  test "unauthorized user cannot delete specimen" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :specimen, :policy => Factory(:private_policy)
    assert_no_difference("Specimen.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to specimens_path
  end

  test "only current user can delete specimen" do

    s = Factory :specimen, :contributor => User.current_user
    assert_difference("Specimen.count", -1, "A specimen should be deleted") do
      delete :destroy, :id => s.id
    end

    s = Factory :specimen
    assert_no_difference("Specimen.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to specimens_path
  end
  test "should not destroy specimen related to an existing sample" do
    sample = Factory :sample
    specimen = Factory :specimen
    specimen.samples = [sample]
    assert_no_difference("Specimen.count") do
      delete :destroy, :id => specimen.id
    end
    assert flash[:error]
    assert_redirected_to specimens_path
  end

  test "should create specimen with strings for confluency passage viability and purity" do
    attrs = [:confluency, :passage, :viability, :purity]
    specimen= Factory.attributes_for :specimen, :confluency => "Test", :passage => "Test", :viability => "Test", :purity => "Test"

    specimen[:strain_id]=Factory(:strain).id
    post :create, :specimen => specimen
    assert specimen = assigns(:specimen)

    assert_redirected_to specimen

    attrs.each do |attr|
      assert_equal "Test", specimen.send(attr)
    end
  end

  test "should show without institution" do
    get :show, :id => Factory(:specimen,
                              :title=>"running mouse NO2 with no institution",
                              :policy =>policies(:editing_for_all_sysmo_users_policy),
                              :institution=>nil)
    assert_response :success
    assert_not_nil assigns(:specimen)
  end
end
