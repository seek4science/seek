# frozen_string_literal: true

class SamplesBatchCreateJob < TaskJob
  queue_with_priority 1
  queue_as QueueNames::SAMPLES

  def perform

  end

  def task
    arguments[0].samples_batch_create_task
  end
end
