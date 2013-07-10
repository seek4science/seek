class RdfGenerationJob < Struct.new(:item_type_name,:item_id, :refresh_dependents)
  DEFAULT_PRIORITY=3

  def perform
    item = item_type_name.constantize.find_by_id(item_id)
    unless item.nil?
      item.save_rdf
      item.send_rdf_to_repository if item.configured_for_rdf_send?
      item.refresh_dependents_rdf if refresh_dependents
    end
  end

  def self.create_job item,refresh_dependents=true,destination_dir=nil,t=Time.now, priority=DEFAULT_PRIORITY
    Delayed::Job.enqueue RdfGenerationJob.new(item.class.name,item.id,refresh_dependents),:priority=>priority,:run_at=>t
  end

end