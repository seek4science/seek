class RdfGenerationJob < Struct.new(:item_type_name,:item_id,:destination_dir)
  DEFAULT_PRIORITY=2

  def perform
    item = item_type_name.constantize.find_by_id(item_id)
    item.save_rdf(destination_dir) unless item.nil?
  end

  def self.create_job item,destination_dir=nil,t=Time.now, priority=DEFAULT_PRIORITY
    Delayed::Job.enqueue RdfGenerationJob.new(item.class.name,item.id,destination_dir),priority,t
  end

end