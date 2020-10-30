class RemoteGitCheckoutJob < SeekJob
  attr_reader :git_repository_id

  def initialize(git_repository)
    @git_repository_id = git_repository.id
  end

  def perform_job(job_item)
    job_item.fetch
  end

  def gather_items
    [GitRepository.find_by_id(git_repository_id)].compact
  end

  def queue_name
    QueueNames::REMOTE_CONTENT
  end
end
