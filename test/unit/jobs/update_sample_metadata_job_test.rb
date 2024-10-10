# frozen_string_literal: true

require 'test_helper'

class UpdateSampleMetadataJobTest < ActiveSupport::TestCase
  def setup
    @person = FactoryBot.create(:person)
    @project = @person.projects.first
    @sample_type = FactoryBot.create(:simple_sample_type, project_ids: [@project.id], contributor: @person, policy: FactoryBot.create(:public_policy))
    (1..10).each do |_i|
      FactoryBot.create(:sample, sample_type: @sample_type, contributor: @person)
    end
  end

  def teardown
    # Do nothing
  end

  test 'perform' do
    User.with_current_user(@person.user) do
      UpdateSampleMetadataJob.new.perform(@sample_type)
    end
  end
end
