require 'test_helper'
require 'minitest/mock'

class ObservationUnitsControllerTest < ActionController::TestCase

  test 'show' do
    unit = FactoryBot.create(:observation_unit)
    get :show, params: { id: unit.id }
    assert_response :success
  end

  test 'index' do
    unit = FactoryBot.create(:observation_unit)
    get :index
    assert_response :success
  end

end