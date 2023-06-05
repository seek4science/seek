require 'test_helper'

class HumanDiseaseApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def setup
    user_login
    @human_disease = FactoryBot.create(:human_disease)
  end

  def skip_index_test?
    true
  end
end
