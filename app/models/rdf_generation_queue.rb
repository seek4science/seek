class RdfGenerationQueue < ApplicationRecord
  include ResourceQueue

  def self.enqueue(*items, refresh_dependents: false, priority: DEFAULT_PRIORITY, queue_job: true)
    super(*items, priority: priority, queue_job: queue_job) do |entry|
      entry.refresh_dependents = refresh_dependents
    end
  end

  def self.job_class
    RdfGenerationJob
  end
end
