# job to periodically call GC and prints heap stats
class OpenbisGarbageJob < SeekJob
  # debug is with puts so it can be easily seen on tests screens
  DEBUG = true

  def initialize(name, delay = 10)
    @name = name
    @delay = delay
  end

  def perform_job(_item)
    Rails.logger.info "Before GC job ObjectSpace\n#{ObjectSpace.count_objects}"
    Rails.logger.info "Before GC stats\n#{GC.stat}"

    GC.start

    Rails.logger.info "After GC job  ObjectSpace\n#{ObjectSpace.count_objects}"
    Rails.logger.info "After GC stats\n#{GC.stat}"
  end

  def gather_items
    [@name]
  end

  def default_priority
    3
  end

  def follow_on_delay
    @delay.minutes
  end

  def follow_on_job?
    true
  end

  def self.create_initial_jobs
    OpenbisGarbageJob.new('GC1').queue_job
  end
end
