class RdfGenerationQueue < ApplicationRecord
  include ResourceQueue

  def self.enqueue(*items, refresh_dependents: false, priority: DEFAULT_PRIORITY, queue_job: true)
    super(*items, priority: priority, queue_job: queue_job) do |entry|
      # Don't set `refresh_dependents` flag to false if existing record
      entry.refresh_dependents = refresh_dependents if entry.new_record? || refresh_dependents
    end
  end

  # Queues the RDF to be generated (and sent to a configured triple store) for every item of every RDF capable type.
  # Returns the names of any types that couldn't be queued.
  def self.enqueue_all
    Seek::Util.rdf_capable_types.sort_by(&:name).filter_map do |type|
      enqueue(type.all, refresh_dependents: false)
      nil
    rescue StandardError => e
      Rails.logger.error("Error queuing RDF generation for #{type.name} - #{e.message}")
      type.name
    end
  end

  def self.job_class
    RdfGenerationJob
  end
end
