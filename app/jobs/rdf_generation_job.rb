class RdfGenerationJob < BatchJob
  BATCHSIZE = 10

  # executes the job - if a triple store is configured it will also update the triple store, otherwise just saves the rdf
  # to a file.
  def perform_job(entry)
    job_item = entry.item
    return unless job_item

    if job_item.rdf_repository_configured?
      job_item.update_repository_rdf
    else
      job_item.delete_rdf_file
      job_item.save_rdf_file
    end

    if entry.refresh_dependents?
      job_item.queue_dependents_rdf_generation
    end
  end

  def gather_items
    entries = RdfGenerationQueue.prioritized.limit(BATCHSIZE)
    entries.destroy_all
  end

  def follow_on_job?
    RdfGenerationQueue.any?
  end
end
