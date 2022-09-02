class RemoteGitFetchJob < TaskJob
  queue_as QueueNames::REMOTE_CONTENT

  def perform(git_repository)
    git_repository.fetch
  end

  def task
    arguments[0].remote_git_fetch_task
  end
end
