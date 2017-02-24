# Job responsible for reacting to an update to a sample type
# refreshes the associated samples, and recreates the editing constraints cache
class SampleTypeUpdateJob < SeekJob
  attr_reader :sample_type_id

  # if refresh_samples is false, then the associated samples won't be refreshed, only the constraints cache rebuilt
  # - defaults to true
  def initialize(sample_type, refresh_samples = true)
    @sample_type_id = sample_type.id
    @refresh_samples = refresh_samples
  end

  def perform_job(item)
    item.refresh_samples if refresh_samples?
    Seek::Samples::SampleTypeEditingConstraints.new(item).refresh_cache
  end

  def gather_items
    [sample_type].compact
  end

  def allow_duplicate_jobs?
    false
  end

  # overrides the default priority, needs to be run soon
  def default_priority
    0
  end

  def queue_name
    QueueNames::SAMPLES
  end

  private

  def refresh_samples?
    @refresh_samples
  end

  def sample_type
    SampleType.find_by_id(sample_type_id)
  end
end
