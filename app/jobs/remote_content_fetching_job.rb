class RemoteContentFetchingJob < SeekJob
  queue_as QueueNames::REMOTE_CONTENT

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
end
