class RemoteGitContentFetchingJob < ApplicationJob
  queue_as QueueNames::REMOTE_CONTENT

  retry_on Seek::DownloadHandling::BadResponseCodeException, wait: 15.seconds, attempts: 3

  def perform(git_version, path, url)
    handler = ContentBlob.remote_content_handler_for(url)
    return unless handler
    io = handler.fetch
    io.rewind
    git_version.add_file(path, io, message: "Fetched #{path} from URL")
    disable_authorization_checks { git_version.save! }
  end
end
