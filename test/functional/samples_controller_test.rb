require "test_helper"

class SamplesControllerTest < ActionController::TestCase
  fixtures :all
  include AuthenticatedTestHelper
  include RestTestCases
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    login_as Factory(:user,:person => Factory(:person,:is_admin=> false))#:owner_of_fully_public_policy
    @object = Factory(:sample,:contributor => User.current_user,
            :title=> "test1",
            :policy => policies(:policy_for_viewable_data_file))
  end

  test "index xml validates with schema" do
    Factory(:sample,
            :title=> "test2",
            :policy => policies(:policy_for_viewable_data_file))
    Factory :sample, :policy => policies(:editing_for_all_sysmo_users_policy)
    get :index, :format =>"xml"
    assert_response :success
    assert_not_nil assigns(:samples)
    validate_xml_against_schema(@response.body)

  end

  test "show xml validates with schema" do
    s = Factory(:sample,:contributor => Factory(:user,:person => Factory(:person,:is_admin=> true)),
                :title => "test sample",
                :policy => policies(:policy_for_viewable_data_file))
    get :show, :id => s, :format =>"xml"
    assert_response :success
    assert_not_nil assigns(:sample)
    validate_xml_against_schema(@response.body)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:samples)
  end
  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:sample)

  end
  test "should create" do
    assert_difference("Sample.count") do
      post :create, :sample => {:title => "test",
                                :lab_internal_number =>"Do232",
                                :donation_date => Date.today,
                                :specimen => Factory(:specimen)}
    end
    s = assigns(:sample)
    assert_redirected_to sample_path(s)
    assert_equal "test", s.title
  end

  test "should get show" do
    get :show, :id => Factory(:sample, :title=>"test", :policy =>policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_not_nil assigns(:sample)
  end

  test "should get edit" do
    get :edit, :id=> Factory(:sample, :policy => policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_not_nil assigns(:sample)
  end
  test "should update" do
    s = Factory(:sample, :title=>"oneSample", :policy =>policies(:editing_for_all_sysmo_users_policy))
    assert_not_equal "test", s.title
    put "update", :id=>s, :sample =>{:title =>"test"}
    s = assigns(:sample)
    assert_redirected_to sample_path(s)
    assert_equal "test", s.title
  end

  test "should destroy" do
    s = Factory :sample, :contributor => User.current_user
    assert_difference("Sample.count", -1, "A sample should be deleted") do
      delete :destroy, :id => s.id
    end
  end
  test "unauthorized users cannot add new samples" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    get :new
    assert_response :redirect
  end
  test "unauthorized user cannot edit sample" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :sample, :policy => Factory(:private_policy)
    get :edit, :id =>s.id
    assert_redirected_to sample_path(s)
    assert flash[:error]
  end
  test "unauthorized user cannot update sample" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :sample, :policy => Factory(:private_policy)

    put :update, :id=> s.id, :sample =>{:title =>"test"}
    assert_redirected_to sample_path(s)
    assert flash[:error]
  end

  test "unauthorized user cannot delete sample" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :sample, :policy => Factory(:private_policy)
    assert_no_difference("Sample.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to samples_path
  end

  test "only current user can delete sample" do

    s = Factory :sample, :contributor => User.current_user
    assert_difference("Sample.count", -1, "A sample should be deleted") do
      delete :destroy, :id => s.id
    end
    s = Factory :sample
    assert_no_difference("Sample.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to samples_path
  end

  test "should not destroy sample related to an existing assay" do
    a = Factory :experimental_assay
    s = Factory :sample
    s.assays = [a]
    assert_no_difference("Sample.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to samples_path
  end
end