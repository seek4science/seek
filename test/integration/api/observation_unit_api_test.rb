require 'test_helper'
class ObservationUnitApiTest < ActionDispatch::IntegrationTest

  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    @creator = FactoryBot.create(:person)
    @project = @current_user.person.projects.first
    @study = FactoryBot.create(:study, contributor: @current_user.person)
    @sample = FactoryBot.create(:sample, contributor: @current_user.person)
    @data_file = FactoryBot.create(:data_file, contributor: @current_user.person)
    @extended_metadata_type = FactoryBot.create(:simple_observation_unit_extended_metadata_type)
    @observation_unit = FactoryBot.create(:observation_unit, contributor: @current_user.person, creators: [@creator])
  end

end
