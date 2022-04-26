require 'test_helper'

class OrganismApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def setup
    admin_login
    @organism = Factory(:organism)
  end
end
