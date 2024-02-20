class SamplesBatchDeleteJob < ApplicationJob
  queue_as QueueNames::SAMPLES
  queue_with_priority 2

  def perform(sample_ids)
    Sample.skip_callback :destroy, :after, :queue_sample_type_update_job
    @sample_types = []
    sample_ids.each_slice(500) do |ids|
      samples = Sample.where(id: ids).includes(:sample_type)
      collect_sample_types(samples)
      disable_authorization_checks do
        Sample.where(id: ids).destroy_all
      end
    end
  ensure
    Sample.set_callback :destroy, :after, :queue_sample_type_update_job
    create_sample_type_update_jobs
  end

  private

  def collect_sample_types(samples)
    @sample_types |= samples.collect(&:sample_type).uniq
  end

  def create_sample_type_update_jobs
    return unless @sample_types.present?

    @sample_types.each do |type|
      SampleTypeUpdateJob.perform_later(type, false)
    end
  end
end
