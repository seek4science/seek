require 'test_helper'

class PublicationApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def setup
    user_login
    @publication = Factory(:publication)
  end
end
