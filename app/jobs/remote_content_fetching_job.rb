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

  def queue_name
    QueueNames::REMOTE_CONTENT
  end
end
