class GalaxyExecutionJob < SeekJob
  attr_reader :data_file_id

  def initialize(data_file)
    @data_file_id = data_file.id
  end

  def perform_job(item)
    item.update_attribute(:status, GalaxyExecutionQueueItem::RUNNING)

    item.update_attribute(:status, GalaxyExecutionQueueItem::FINISHED)
  end

  def gather_items
    [GalaxyExecutionQueueItem.where(data_file_id: data_file_id).where(status: GalaxyExecutionQueueItem::QUEUED).first].compact
  end

  def timelimit
    120.minutes
  end

end