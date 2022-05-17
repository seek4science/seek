class RemoteGitContentFetchingJob < ApplicationJob
  queue_as QueueNames::REMOTE_CONTENT

  retry_on Seek::DownloadHandling::BadResponseCodeException, wait: 1.minute, attempts: 3

  def perform(git_version, path, _ = nil)
    disable_authorization_checks do
      git_version.fetch_remote_file(path)
      git_version.save!
    end
  end
end
