require 'test_helper'

class ObservationUnitTest < ActiveSupport::TestCase

  test 'max factory' do
    obs_unit = FactoryBot.create(:max_observation_unit)
    refute_nil obs_unit.created_at
    refute_nil obs_unit.updated_at
    refute_empty obs_unit.projects
    refute_empty obs_unit.creators
    refute_nil obs_unit.other_creators
    refute_nil obs_unit.extended_metadata
    refute_nil obs_unit.extended_metadata.extended_metadata_type
  end

end