require 'test_helper'
class ObservationUnitApiTest < ActionDispatch::IntegrationTest

  include ReadApiTestSuite
  #include WriteApiTestSuite

  def setup
    @observation_unit = FactoryBot.create(:observation_unit)
  end

end
