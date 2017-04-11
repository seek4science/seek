class RemoteContentFetchingJob < SeekJob
  attr_reader :content_blob_id

  def initialize(content_blob)
    @content_blob_id = content_blob.id
  end

  def perform_job(job_item)
    job_item.retrieve
  end

  def gather_items
    [ContentBlob.find_by_id(content_blob_id)].compact
  end

  def queue_name
    QueueNames::REMOTE_CONTENT
  end
end
