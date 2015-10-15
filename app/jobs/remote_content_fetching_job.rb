class RemoteContentFetchingJob < SeekJob
  attr_reader :content_blob

  def initialize(content_blob)
    @content_blob = content_blob
  end

  def perform_job(job_item)
    job_item.retrieve
  end

  def gather_items
    [content_blob]
  end

  def self.queue_name
    'remotecontent'
  end

  def queue_name
    self.class.queue_name
  end
end
