# job to periodically call GC and prints heap stats
class OpenbisGarbageJob < ApplicationJob
  queue_with_priority 3
  # debug is with puts so it can be easily seen on tests screens
  DEBUG = true

  def perform
    Rails.logger.info "Before GC job ObjectSpace\n#{ObjectSpace.count_objects}"
    Rails.logger.info "Before GC stats\n#{GC.stat}"

    GC.start

    Rails.logger.info "After GC job  ObjectSpace\n#{ObjectSpace.count_objects}"
    Rails.logger.info "After GC stats\n#{GC.stat}"
  end

  after_perform do |job|
    job.class.set(wait: 10.minutes).perform_later
  end

  def self.create_initial_jobs
    OpenbisGarbageJob.new.queue_job
  end
end
