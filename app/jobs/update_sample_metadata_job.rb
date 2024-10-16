# frozen_string_literal: true

class UpdateSampleMetadataJob < ApplicationJob
  queue_with_priority 1
  queue_as QueueNames::SAMPLES

  def perform(sample_type, attribute_changes = [], user)
    Seek::Samples::SampleMetadataUpdater.new(sample_type, attribute_changes, user).update_metadata
  end
end
