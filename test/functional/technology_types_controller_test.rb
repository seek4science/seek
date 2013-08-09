require 'test_helper'

class TechnologyTypesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object=technology_types(:gas_chromatography)
  end

  test "show" do
    login_as(:quentin)
    get :show,:id=>technology_types(:gas_chromatography)
    assert_response :success
  end

  test "should show technology types to public" do
    logout
    get :show, :id => technology_types(:technology_type_with_child)
    assert_response :success
    assert_not_nil assigns(:technology_type)
  end

  test 'should show only related authorized assays' do
    assays = technology_types(:child_technology_type_with_assay).assays
    authorized_assays = assays.select(&:can_view?)
    assert_equal 2, assays.count
    assert_equal 1, authorized_assays.count

    get :show, :id => technology_types(:child_technology_type_with_assay)
    assert_response :success
    assert_select 'a', :text => authorized_assays.first.title, :count => 1
    assert_select 'a', :text => (assays - authorized_assays).first.title, :count => 0
  end

end
