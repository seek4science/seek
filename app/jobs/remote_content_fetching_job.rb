class RemoteContentFetchingJob < TaskJob
  queue_as QueueNames::REMOTE_CONTENT

  def perform(content_blob)
    content_blob.retrieve
  end

  def task
    arguments[0].remote_content_fetch_task
  end
end
