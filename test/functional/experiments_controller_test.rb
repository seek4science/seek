require 'test_helper'

class ExperimentsControllerTest < ActionController::TestCase
  fixtures :experiments,:assays,:assay_types,:topics,:projects,:users,:people

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:experiments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => experiments(:metabolomics_exp)
    assert_response :success
  end

  def test_should_show_experiment
    get :show, :id => experiments(:metabolomics_exp)
    assert_response :success
  end

  def test_should_destroy_experiment
    assert_difference('Experiment.count', -1) do
      delete :destroy, :id => experiments(:metabolomics_exp)
    end
    assert_redirected_to experiments_path
  end

  def test_non_admin_should_not_destroy_experiment
    login_as(:aaron)
    assert_no_difference('Experiment.count') do
      delete :destroy, :id => experiments(:metabolomics_exp)
    end
  end
  
end
