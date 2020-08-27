class RdfGenerationJob < SeekJob
  BATCHSIZE = 10

  # executes the job - if a triple store is configured it will also update the triple store, otherwise just saves the rdf
  # to a file.
  def perform_job(job_item)
    if job_item.rdf_repository_configured?
      job_item.update_repository_rdf
    else
      job_item.delete_rdf_file
      job_item.save_rdf_file
    end
  end

  def gather_items
    RdfGenerationQueue.dequeue(BATCHSIZE)
  end
end
