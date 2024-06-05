class ReindexingQueue < ApplicationRecord
  include ResourceQueue

  def self.enqueue(*items, priority: DEFAULT_PRIORITY, queue_job: true)
    return unless Seek::Config.solr_enabled
    super(items, priority: priority, queue_job: queue_job)
  end

  def self.job_class
    ReindexingJob
  end

end
