require 'test_helper'

class GitRepositoryTest < ActiveSupport::TestCase

  test 'init local repo' do
    repo = Factory(:local_repository)
    assert File.exist?(File.join(repo.local_path, '.git', 'config'))
  end

  test 'fetch remote' do # Remote in this case is a local path, because we don't want to use the network
    repo = Factory(:remote_repository)
    # Could use rubyzip for this
    RemoteGitFetchJob.perform_now(repo)
    remote = repo.git_base.remotes.first

    assert_equal 'origin', remote.name
    assert remote.url.end_with?('seek4science/workflow-test-fixture.git')
    assert File.exist?(File.join(repo.local_path, '.git', 'config'))
  ensure
    FileUtils.rm_rf(repo.remote) if repo
  end
end
