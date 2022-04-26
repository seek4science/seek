require 'test_helper'

class OrganismApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def model
    Organism
  end

  def setup
    admin_login
    @organism = Factory(:organism)
  end
end
