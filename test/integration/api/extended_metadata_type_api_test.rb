require 'test_helper'

class ExtendedMetadataTypeApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def setup
    person = FactoryBot.create(:person)
    refute person.is_admin?
    user_login(person)
  end
end
