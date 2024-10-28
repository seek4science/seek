# frozen_string_literal: true

class UpdateSampleMetadataJob < ApplicationJob
  queue_with_priority 1
  queue_as QueueNames::SAMPLES

  def perform(sample_type, user, attribute_changes = [])
    begin
      Rails.cache.write("sample_type_lock_#{sample_type.id}", true, expires_in: 1.hour)
      sample_type.lock.samples.in_batches(of: 1000) do |samples|
        Seek::Samples::SampleMetadataUpdater.new(samples, user, attribute_changes).update_metadata
      end
    end
  ensure
    Rails.cache.delete("sample_type_lock_#{sample_type.id}")
  end
end
