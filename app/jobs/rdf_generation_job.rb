class RdfGenerationJob < Struct.new(:item_type_name,:item_id)
  DEFAULT_PRIORITY=3

  def perform
    item = item_type_name.constantize.find_by_id(item_id)
    item.save_rdf unless item.nil?
  end

  def self.create_job item,destination_dir=nil,t=Time.now, priority=DEFAULT_PRIORITY
    Delayed::Job.enqueue RdfGenerationJob.new(item.class.name,item.id),:priority=>priority,:run_at=>t
  end

end