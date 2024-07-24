# frozen_string_literal: true

class UpdateSampleMetadataJob < ApplicationJob
  queue_with_priority 1
  queue_as QueueNames::SAMPLES

  def perform(sample_type)
    Seek::Samples::SampleMetadataUpdater.new(sample_type).update_metadata
  end
end
