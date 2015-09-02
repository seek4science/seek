class RdfGenerationJob < SeekJob
  attr_reader :item_type_name, :item_id, :refresh_dependents

  def initialize(item, refresh_dependents = true)
    @item_type_name = item.class.name
    @item_id = item.id
    @refresh_dependents = refresh_dependents
  end

  # executes the job - if a triple store is configured it will also update the triple store, otherwise just saves the rdf
  # to a file.
  def perform_job(job_item)
    if job_item.rdf_repository_configured?
      job_item.update_repository_rdf
    else
      job_item.delete_rdf_file
      job_item.save_rdf_file
    end
    job_item.refresh_dependents_rdf if refresh_dependents
  end

  def gather_items
    [item].compact
  end

  def item
    item_type_name.constantize.find_by_id(item_id)
  end

  def exists?
    result = super

    # if we don't want to refresh_dependents, but a job exists that does, then we can say it exists
    unless result || refresh_dependents
      result = RdfGenerationJob.new(item, true).exists?
    end
    result
  end
end
