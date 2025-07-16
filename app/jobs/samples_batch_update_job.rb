# frozen_string_literal: true

class SamplesBatchUpdateJob < TaskJob
  def perform

  end

  def task
    arguments[0].samples_batch_update_task
  end
end
