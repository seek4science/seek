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
      UpdateSampleMetadataJob.new.perform(@sample_type, [], @person.user)
    end
  end

  test 'Check sample metadata after updating the attribute title' do
    assert_equal @sample_type.sample_attributes.first.title, 'the_title'
    @sample_type.sample_attributes.first.update!(title: 'new title')
    attribute_change_maps = [{id: @sample_type.sample_attributes.first.id, old_title: 'the_title', new_title: 'new title' }]
    assert_equal @sample_type.sample_attributes.first.title, 'new title'
    refute_equal @sample_type.sample_attributes.first.title, 'the_title'
    UpdateSampleMetadataJob.new.perform(@sample_type, attribute_change_maps, @person.user)
    @sample_type.samples.each do |sample|
      json_metadata = JSON.parse sample.json_metadata
      assert json_metadata.keys.include?('new title')
      refute json_metadata.keys.include?('the_title')
    end
  end
end
