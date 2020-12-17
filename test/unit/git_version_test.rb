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
    assert_equal 'This Workflow', v.proxy.title
    assert v.mutable?

    v.send(:freeze_version)
    workflow.update_column(:title, 'Something else')
    new_class = Factory(:galaxy_workflow_class)
    workflow.update_column(:workflow_class_id, new_class.id)

    assert_not_empty v.metadata
    assert_equal 'This Workflow', v.metadata['title']
    assert_equal 'This Workflow', v.proxy.title
    assert_equal 'cwl', v.proxy.workflow_class.key
    assert_equal 'galaxy', workflow.workflow_class.key
    refute v.mutable?
  ensure
    FileUtils.rm_rf(repo.remote)
  end

  test 'add file' do
    repo = Factory(:local_repository)
    workflow = repo.resource

    v = workflow.git_versions.create!(mutable: true)
    assert_equal 'This Workflow', v.proxy.title
    assert v.mutable?
    assert v.commit.blank?

    v.add_file('blah.txt', StringIO.new('blah'))

    assert v.commit.present?
    assert_includes v.blobs.keys, 'blah.txt'
    assert_equal 'blah', v.file_contents('blah.txt')
  end

  test 'cannot add file to immutable version' do
    repo = Factory(:local_repository)
    workflow = repo.resource

    v = workflow.git_versions.create!(mutable: false)
    assert_equal 'This Workflow', v.proxy.title
    refute v.mutable?
    assert v.commit.blank?

    assert_raise(GitVersion::ImmutableVersionException) do
      v.add_file('blah.txt', StringIO.new('blah'))
    end

    assert v.commit.blank?
    assert_empty v.blobs
  end

  test 'automatically init local git repo' do
    w = Factory(:workflow)
    v = w.git_versions.create

    assert v.git_repository
    assert w.local_git_repository
    assert_equal w.local_git_repository, v.git_repository
  end

  test 'automatically link existing remote git repos' do
    w = Factory(:workflow)
    v = w.git_versions.create(git_repository_remote: 'https://git.git/git.git')
    w2 = Factory(:workflow)
    v2 = w2.git_versions.create(git_repository_remote: 'https://git.git/git.git')

    assert_nil w.local_git_repository
    assert_nil w2.local_git_repository
    assert_equal v.git_repository, v2.git_repository
  end

end
