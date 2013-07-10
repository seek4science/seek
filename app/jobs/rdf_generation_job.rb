class RdfGenerationJob < Struct.new(:item_type_name,:item_id)
  DEFAULT_PRIORITY=3

  def perform
    item = item_type_name.constantize.find_by_id(item_id)
    unless item.nil?
      item.save_rdf
      item.send_rdf if item.configured_for_rdf_send?
    end
    item.save_rdf unless item.nil?
  end

  def self.create_job item,destination_dir=nil,t=Time.now, priority=DEFAULT_PRIORITY
    Delayed::Job.enqueue RdfGenerationJob.new(item.class.name,item.id),:priority=>priority,:run_at=>t
  end

end