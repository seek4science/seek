class RdfGenerationQueue < ApplicationRecord
  include ResourceQueue

  def self.enqueue(*items, refresh_dependents: false, priority: DEFAULT_PRIORITY, queue_job: true)
    super(*items, priority: priority, queue_job: queue_job) do |entry|
      # Don't set `refresh_dependents` flag to false if existing record
      entry.refresh_dependents = refresh_dependents if entry.new_record? || refresh_dependents
    end
  end

  # Queues the RDF to be generated (and sent to the triple store, if one is configured) for every item of every RDF
  # capable type. Returns the names of any types that couldn't be queued.
  def self.enqueue_all
    failed = Seek::Util.rdf_capable_types.sort_by(&:name).filter_map do |type|
      type.find_in_batches { |batch| enqueue(batch, queue_job: false) }
      nil
    rescue StandardError => e
      Rails.logger.error("Error queuing RDF generation for #{type.name} - #{e.message}")
      type.name
    end
    job_class.new.queue_job
    failed
  end

  def self.job_class
    RdfGenerationJob
  end
end
