class RdfGenerationJob < SeekJob

  attr_reader :item,:refresh_dependants

  def initialize(item,refresh_dependants=true)
    @item=item
    @refresh_dependants=refresh_dependants
  end

  #executes the job - if a triple store is configured it will also update the triple store, otherwise just saves the rdf
  #to a file.
  def perform_job item
    if item.rdf_repository_configured?
      item.update_repository_rdf
    else
      item.delete_rdf_file
      item.save_rdf_file
    end
    item.refresh_dependents_rdf if refresh_dependents
  end

  def gather_items
    [item].compact
  end

  def job_yaml
    RdfGenerationJob.new(item,refresh_dependants).to_yaml
  end

  def default_delay
    1.seconds
  end

  def default_priority
    3
  end

  def exists?
    result = super

    #if we don't want to refresh_dependents, but a job exists that does, then we can say it exists
    unless result || refresh_dependants
      result = RdfGenerationJob.new(item,true).exists?
    end
    result
  end

end