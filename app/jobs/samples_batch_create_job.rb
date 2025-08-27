# frozen_string_literal: true

class SamplesBatchCreateJob < ApplicationJob
  queue_with_priority 1
  queue_as QueueNames::SAMPLES

  def perform(sample_type_id, parameters, user, send_email)
    processor = Samples::SampleBatchProcessor.new(sample_type_id:, new_sample_params: parameters, updated_sample_params: [], user:, send_email:)
    processor.create!
  end
end
