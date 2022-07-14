# Job responsible for reacting to an update to a sample type
# refreshes the associated samples, and recreates the editing constraints cache
class SampleTypeUpdateJob < ApplicationJob
  queue_as QueueNames::SAMPLES
  queue_with_priority 1

  # if refresh_samples is false, then the associated samples won't be refreshed, only the constraints cache rebuilt
  # - defaults to true
  def perform(sample_type, refresh_samples)
    if refresh_samples
      sample_type.refresh_samples
      Rails.cache.delete_matched(%r{#{sample_type.list_item_title_cache_key_prefix}/samples.*})
    end

    Seek::Samples::SampleTypeEditingConstraints.new(sample_type).refresh_cache
  end
end
