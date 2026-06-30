require 'test_helper'

class UuidsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test 'show' do
    m = models(:model_with_format_and_type)
    get :show, params: { id: m.uuid }
    assert_redirected_to m
  end

  test 'show2' do
    assay = assays(:metabolomics_assay2)
    get :show, params: { id: assay.uuid }
    assert_redirected_to assay
  end

  test 'not found' do
    get :show, params: { id: "#{assays(:metabolomics_assay2).uuid}x" }
    assert_includes flash[:error], 'Not Found'
  end
end
