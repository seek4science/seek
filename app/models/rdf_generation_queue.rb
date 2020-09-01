class RdfGenerationQueue < ApplicationRecord
  include ResourceQueue

  def self.enqueue(*items, refresh_dependents: false, priority: DEFAULT_PRIORITY, queue_job: true)
    super(*items, priority: priority, queue_job: queue_job) do |entry|
      # Don't set `refresh_dependents` flag to false if existing record
      entry.refresh_dependents = refresh_dependents if entry.new_record? || refresh_dependents
    end
  end

  def self.job_class
    RdfGenerationJob
  end
end
