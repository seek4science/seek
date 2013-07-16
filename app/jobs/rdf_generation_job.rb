class RdfGenerationJob < Struct.new(:item_type_name,:item_id, :refresh_dependents)
  DEFAULT_PRIORITY=3

  def perform
    item = item_type_name.constantize.find_by_id(item_id)
    unless item.nil?
      begin
        if item.rdf_repository_configured?
          item.update_repository_rdf
        else
          item.delete_rdf
          item.save_rdf
        end
        item.refresh_dependents_rdf if refresh_dependents
      rescue Exception=>e
        Rails.logger.error("Error generating rdf for #{item.class.name} - #{item.id}: #{e.message}")
      end
    end
  end

  def self.exists? item, refresh_dependents=true
    yml = RdfGenerationJob.new(item.class.name,item.id,refresh_dependents).to_yaml
    result = Delayed::Job.where(['handler = ? AND locked_at IS ? AND failed_at IS ?',yml,nil,nil]).count>0

    #if we don't want to refresh_dependents, but a job exists that does, then we can say it exists
    unless result || refresh_dependents
      result = self.exists?(item,true)
    end
    result
  end

  def self.create_job item,refresh_dependents=true,t=Time.now, priority=DEFAULT_PRIORITY
    unless self.exists?(item,refresh_dependents)
      Delayed::Job.enqueue RdfGenerationJob.new(item.class.name,item.id,refresh_dependents),:priority=>priority,:run_at=>t
    end
  end

end