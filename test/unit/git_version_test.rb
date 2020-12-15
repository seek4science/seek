require 'test_helper'

class GitVersionTest < ActiveSupport::TestCase
  setup do
    WebMock.disable_net_connect!
    FileUtils.rm_r(Seek::Config.git_filestore_path)
    FileUtils.rm_r(Seek::Config.git_temporary_filestore_path)
  end

  test 'freeze version attributes' do
    repo = Factory(:remote_repository)
    workflow = repo.resource
    # Could use rubyzip for this
    `unzip -qq #{repo.remote}.zip -d #{Pathname.new(repo.remote).parent}`
    RemoteGitCheckoutJob.new(repo).perform

    v = workflow.git_versions.create!(target: 'master', mutable: true)
    assert_empty v.metadata
    assert_equal 'This Workflow', v.title
    assert v.mutable?

    v.send(:freeze_version)
    workflow.update_column(:title, 'Something else')

    assert_not_empty v.metadata
    assert_equal 'This Workflow', v.metadata['title']
    assert_equal 'This Workflow', v.title
    refute v.mutable?
  ensure
    FileUtils.rm_rf(repo.remote)
  end
end
