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

    v = workflow.git_versions.create!(ref: 'refs/heads/master', mutable: true)
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

  test 'add files' do
    repo = Factory(:local_repository)
    workflow = repo.resource

    v = workflow.git_versions.create!(mutable: true)
    assert_equal 'This Workflow', v.proxy.title
    assert v.mutable?
    assert v.commit.blank?

    v.add_file('blah.txt', StringIO.new('blah'))
    v.add_file('hello/whatever.txt', StringIO.new('whatever'))
    assert v.commit.present?
    assert v.file_exists?('blah.txt')
    assert v.file_exists?('hello/whatever.txt')
    assert_equal 'blah', v.file_contents('blah.txt')
    assert_equal 'whatever', v.file_contents('hello/whatever.txt')
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
    w = Factory(:workflow, git_version_attributes: { git_repository_remote: 'https://git.git/git.git' })
    w2 = Factory(:workflow, git_version_attributes: { git_repository_remote: 'https://git.git/git.git' })

    assert_nil w.local_git_repository
    assert_nil w2.local_git_repository
    assert_equal w.latest_git_version.git_repository, w2.latest_git_version.git_repository
  end

  test 'create git version on create' do
    # Make sure remote repo exists
    Factory(:workflow, git_version_attributes: { git_repository_remote: 'https://git.git/git.git' })

    assert_difference('GitVersion.count', 1) do
      assert_no_difference('GitRepository.count') do
        w = Factory(:workflow, title: 'Test', description: 'Testy', git_version_attributes: {
            ref: 'refs/heads/master',
            git_repository_remote: 'https://git.git/git.git'
        })
        assert_equal 1, w.git_versions.count

        v = w.git_versions.last
        assert_equal 'Test', v.proxy.title
        assert_equal 'Testy', v.proxy.description
        assert_equal 'https://git.git/git.git', v.git_repository.remote
        assert_equal 'refs/heads/master', v.ref
      end
    end
  end

  test 'create git version with local repo and defaults on create' do
    assert_difference('GitVersion.count', 1) do
      assert_difference('GitRepository.count', 1) do
        w = Factory(:workflow, title: 'Test', description: 'Testy')
        assert_equal 1, w.git_versions.count

        v = w.git_versions.last
        assert_equal 'Test', v.proxy.title
        assert_equal 'Testy', v.proxy.description
        assert_nil v.git_repository.remote
        assert_equal 'refs/heads/master', v.ref, 'Ref should be master by default'
        assert_equal 'Version 1', v.name
      end
    end
  end

  test 'resolve refs' do
    remote = Factory(:remote_repository)

    workflow = remote.resource
    # v = workflow.git_versions.create!(mutable: false)
    # assert_equal '068cecdfce022aa98532026957a0c9519402e156', v.commit
    v = workflow.git_versions.create!(git_repository_remote: remote.remote, ref: 'refs/heads/master')
    assert_equal '068cecdfce022aa98532026957a0c9519402e156', v.commit
    v = workflow.git_versions.create!(git_repository_remote: remote.remote, ref: 'refs/tags/v1.10.0')
    assert_equal 'cc448436c3352c48e94e15e563c7639093e7f4ef', v.commit
  end
end
