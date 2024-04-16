require 'test_helper'

class ExtendedMetadataTypeApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def setup
    user_login(FactoryBot.create(:admin))
  end
end
