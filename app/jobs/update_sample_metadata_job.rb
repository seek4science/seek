# frozen_string_literal: true

class UpdateSampleMetadataJob < TaskJob
  queue_with_priority 1
  queue_as QueueNames::SAMPLES

  def perform(sample_type, user, attribute_changes = [])
    @sample_type = sample_type
    @user = user
    @attribute_changes = attribute_changes

    Seek::Samples::SampleMetadataUpdater.new(@sample_type, @user, @attribute_changes).update_metadata
  end

  def task
    arguments[0].sample_metadata_update_task
  end
end
