# frozen_string_literal: true

class SamplesBatchUploadJob < TaskJob
  queue_with_priority 1
  queue_as QueueNames::SAMPLES

  def perform(sample_type_id, new_sample_params, updated_sample_params, user, send_email)
    processor = Samples::SampleBatchProcessor.new(sample_type_id:, new_sample_params:, updated_sample_params:, user:, send_email:)
    processor.process!
  end

  def task
    sample_type = SampleType.find(arguments[0])
    sample_type.sample_batch_upload_task
  end
end
