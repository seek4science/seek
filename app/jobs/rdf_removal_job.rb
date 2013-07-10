class RdfRemovalJob < Struct.new(:item_type_name,:item_id)
  DEFAULT_PRIORITY=2 #must be a higher priority (lower number)than the generation job, as it relies on the contents of the previous rdf file

  def perform
    item = item_type_name.constantize.find_by_id(item_id)
    item.delete_rdf
  end

  def self.create_job item,destination_dir=nil,t=Time.now, priority=DEFAULT_PRIORITY
    Delayed::Job.enqueue RdfRemovalJob.new(item.class.name,item.id),:priority=>priority,:run_at=>t
  end

end