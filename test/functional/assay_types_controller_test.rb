require 'test_helper'

class AssayTypesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:aaron)
  end

  def rest_api_test_object
    @object=assay_types(:metabolomics)
  end

  test "show" do
    login_as(:quentin)
    get :show,:id=>assay_types(:metabolomics)
    assert_response :success
  end

  test "should show assay types to public" do
    logout
    get :show, :id => assay_types(:metabolomics)
    assert_response :success
    assert_not_nil assigns(:assay_type)
  end

  #test 'should show only related authorized assays' do
  #  assays = assay_types(:child_assay_type_with_assay).assays
  #  authorized_assays = assays.select(&:can_view?)
  #  assert_equal 2, assays.count
  #  assert_equal 1, authorized_assays.count
  #
  #  get :show, :id => assay_types(:child_assay_type_with_assay)
  #  assert_response :success
  #  assert_select 'a', :text => authorized_assays.first.title, :count => 1
  #  assert_select 'a', :text => (assays - authorized_assays).first.title, :count => 0
  #end



end
