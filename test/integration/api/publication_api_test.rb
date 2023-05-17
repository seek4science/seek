require 'test_helper'

class PublicationApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def setup
    user_login
    @publication = FactoryBot.create(:publication)
  end
end
