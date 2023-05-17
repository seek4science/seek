require 'test_helper'

class GitRepositoryTest < ActiveSupport::TestCase

  test 'init local repo' do
    repo = FactoryBot.create(:local_repository)
    assert File.exist?(File.join(repo.local_path, '.git', 'config'))
  end

  test 'fetch remote' do
    repo = FactoryBot.create(:remote_repository)
    RemoteGitFetchJob.perform_now(repo)
    remote = repo.git_base.remotes.first

    assert_equal 'origin', remote.name
    assert remote.url.end_with?('seek4science/workflow-test-fixture.git')
    assert File.exist?(File.join(repo.local_path, '.git', 'config'))
  ensure
    FileUtils.rm_rf(repo.remote) if repo
  end

  test "don't fetch if recently fetched" do
    repo = FactoryBot.create(:remote_repository, last_fetch: 5.minutes.ago)
    assert_no_difference('Task.count') do
      assert_no_enqueued_jobs(only: RemoteGitFetchJob) do
        repo.queue_fetch
      end
    end
  end

  test "fetch even if recently fetched with force option set" do
    repo = FactoryBot.create(:remote_repository, last_fetch: 5.minutes.ago)
    assert_difference('Task.count', 1) do
      assert_enqueued_jobs(1, only: RemoteGitFetchJob) do
        repo.queue_fetch(true)
      end
    end
  end

  test "fetch if not recently fetched" do
    repo = FactoryBot.create(:remote_repository, last_fetch: 30.minutes.ago)
    assert_difference('Task.count', 1) do
      assert_enqueued_jobs(1, only: RemoteGitFetchJob) do
        repo.queue_fetch
      end
    end
  end

  test 'redundant repositories' do
    redundant = Git::Repository.create!
    not_redundant = FactoryBot.create(:git_version).git_repository

    repositories = Git::Repository.redundant.to_a

    assert_includes repositories, redundant
    assert_not_includes repositories, not_redundant
  end
end
