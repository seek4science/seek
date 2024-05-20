require 'test_helper'
require 'minitest/mock'

class ObservationUnitsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include GeneralAuthorizationTestCases
  include RdfTestCases

  def rdf_test_object
    FactoryBot.create(:max_observation_unit)
  end

  test 'show' do
    unit = FactoryBot.create(:max_observation_unit)
    get :show, params: { id: unit.id }
    assert_response :success
  end

  test 'index' do
    unit = FactoryBot.create(:max_observation_unit)
    get :index
    assert_response :success
  end

  test 'edit' do
    unit = FactoryBot.create(:max_observation_unit)
    login_as(unit.contributor)
    get :edit, params: { id: unit.id}
    assert_response :success
  end

  test 'manage' do
    unit = FactoryBot.create(:max_observation_unit)
    login_as(unit.contributor)
    get :manage, params: { id: unit.id}
    assert_response :success
  end

end