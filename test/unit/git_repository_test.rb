require 'test_helper'

class GitRepositoryTest < ActiveSupport::TestCase
  setup do
    WebMock.disable_net_connect!
    FileUtils.rm_r(Seek::Config.git_filestore_path)
    FileUtils.rm_r(Seek::Config.git_temporary_filestore_path)
  end

  test 'init local repo' do
    repo = Factory(:local_repository)
    assert File.exist?(File.join(repo.local_path, '.git', 'config'))
  end

  test 'fetch remote' do # Remote in this case is a local path, because we don't want to use the network
    repo = Factory(:remote_repository)
    # Could use rubyzip for this
    `unzip -qq #{repo.remote}.zip -d #{Pathname.new(repo.remote).parent}`
    RemoteGitFetchJob.perform_now(repo)
    remote = repo.git_base.remotes.first

    assert_equal 'origin', remote.name
    assert remote.url.end_with?('nf-core/chipseq')
    assert File.exist?(File.join(repo.local_path, '.git', 'config'))
  ensure
    FileUtils.rm_rf(repo.remote) if repo
  end
end
