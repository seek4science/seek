require 'test_helper'

class OrganismApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def setup
    user_login
    @organism = FactoryBot.create(:organism)
  end
end
