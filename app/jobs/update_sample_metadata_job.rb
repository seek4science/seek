# frozen_string_literal: true

class UpdateSampleMetadataJob < ApplicationJob
  queue_with_priority 1
  queue_as QueueNames::SAMPLES

  def perform(sample_type, user, attribute_changes = [])
    sample_type.samples.in_batches(of: 1000) do |samples|
      Seek::Samples::SampleMetadataUpdater.new(samples, user, attribute_changes).update_metadata
    end
  end
end
