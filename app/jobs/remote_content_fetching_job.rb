class RemoteContentFetchingJob < ApplicationJob
  queue_as QueueNames::REMOTE_CONTENT

  def perform(content_blob)
    content_blob.retrieve
  end
end
