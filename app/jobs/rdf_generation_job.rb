class RdfGenerationJob < Struct.new(:item_type_name,:item_id, :refresh_dependents)
  DEFAULT_PRIORITY=3

  #executes the job - if a triple store is configured it will also update the triple store, otherwise just saves the rdf
  #to a file.
  def perform
    item = item_type_name.constantize.find_by_id(item_id)
    unless item.nil?
      begin
        if item.rdf_repository_configured?
          item.update_repository_rdf
        else
          item.delete_rdf_file
          item.save_rdf_file
        end
        item.refresh_dependents_rdf if refresh_dependents
      rescue Exception=>e
        Rails.logger.error("Error generating rdf for #{item.class.name} - #{item.id}: #{e.message}")
      end
    end
  end

  #indicates whether a job already exists. If refresh_dependents=false it will be considered to exist even if it exists with
  #refresh_job=true - but not the other away around
  def self.exists? item, refresh_dependents=true
    yml = RdfGenerationJob.new(item.class.name,item.id,refresh_dependents).to_yaml
    result = Delayed::Job.where(['handler = ? AND locked_at IS ? AND failed_at IS ?',yml,nil,nil]).count>0

    #if we don't want to refresh_dependents, but a job exists that does, then we can say it exists
    unless result || refresh_dependents
      result = self.exists?(item,true)
    end
    result
  end

  #creates a new job, if it doesn't already exist
  def self.create_job item,refresh_dependents=true,t=Time.now, priority=DEFAULT_PRIORITY
    unless self.exists?(item,refresh_dependents)
      Delayed::Job.enqueue RdfGenerationJob.new(item.class.name,item.id,refresh_dependents),:priority=>priority,:run_at=>t
    end
  end

end