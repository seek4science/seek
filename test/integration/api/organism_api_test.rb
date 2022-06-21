require 'test_helper'

class OrganismApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def setup
    user_login
    @organism = Factory(:organism)
  end
end
