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

  test 'perform' do
    User.with_current_user(@person.user) do
      UpdateSampleMetadataJob.perform_now(@sample_type, @person.user, [])
      assert_enqueued_with(job: SampleTypeUpdateJob, args: [@sample_type, true])
    end
  end

  test 'enqueue' do
    # Simulate the lock in the cache from the controller
    job = UpdateSampleMetadataJob.new(@sample_type, @person.user, [])
    User.with_current_user(@person.user) do
      assert_enqueued_with(job: UpdateSampleMetadataJob, args: [@sample_type, @person.user, []]) do
        job.enqueue
      end
      assert @sample_type.locked?

      perform_enqueued_jobs do
        job.perform_now
      end

      refute @sample_type.locked?
    end
  end

  test 'Check sample metadata after updating the attribute title' do
    User.with_current_user(@person.user) do
      @sample_type.sample_attributes.first.update!(title: 'new title')
      attribute_change_maps = [{id: @sample_type.sample_attributes.first.id, old_title: 'the_title', new_title: 'new title' }]
      assert_equal @sample_type.sample_attributes.first.title, 'new title'
      refute_equal @sample_type.sample_attributes.first.title, 'the_title'
      UpdateSampleMetadataJob.perform_now(@sample_type, @person.user, attribute_change_maps)
      refute @sample_type.locked?
      @sample_type.reload
      @sample_type.samples.each do |sample|
        json_metadata = JSON.parse sample.json_metadata
        assert json_metadata.keys.include?('new title')
        refute json_metadata.keys.include?('the_title')
      end
    end
  end

  test 'perform with unexpected error' do
    # Clears the queue of all jobs
    # Queue has already multiple SampleTypeUpdateJob jobs from the setup
    clear_enqueued_jobs
    job = UpdateSampleMetadataJob.new(@sample_type, @person.user, 'bad_attribute_change_map')
    assert_enqueued_with(job: UpdateSampleMetadataJob, args: [@sample_type, @person.user, 'bad_attribute_change_map']) do
      job.enqueue
    end
    assert @sample_type.locked?

    perform_enqueued_jobs do
      job.perform_now
    end
    # The sample type should be unlocked even if an error occurs
    refute @sample_type.locked?
    # SampleTypeUpdateJob should not be enqueued when an error occurs
    assert_no_enqueued_jobs only: SampleTypeUpdateJob
  end
end
