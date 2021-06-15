require 'test_helper'

class GitVersionTest < ActiveSupport::TestCase
  setup do
  end

  test 'lock version' do
    repo = Factory(:local_repository)
    workflow = repo.resource

    v = workflow.git_versions.create!(name: 'version 1.0.0', ref: 'refs/heads/master', mutable: true)
    assert_empty v.resource_attributes
    assert_equal 'This Workflow', v.title
    refute v.git_base.tags['version-1.0.0']
    assert v.mutable?

    v.send(:lock)
    workflow.update_column(:title, 'Something else')
    new_class = WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class)
    workflow.update_column(:workflow_class_id, new_class.id)

    assert_equal 'refs/tags/version-1.0.0', v.ref
    assert v.git_base.tags['version-1.0.0']
    assert_not_empty v.resource_attributes
    assert_equal 'This Workflow', v.resource_attributes['title']
    assert_equal 'This Workflow', v.title
    assert_equal 'cwl', v.workflow_class.key
    assert_equal 'galaxy', workflow.workflow_class.key
    refute v.mutable?
  end

  test 'add files' do
    workflow = Factory(:workflow)
    repo = Factory(:blank_repository, resource: workflow)

    v = workflow.git_versions.create!(mutable: true)
    assert_equal 'This Workflow', v.title
    assert v.mutable?
    assert v.commit.blank?
    assert_empty v.blobs

    v.add_file('blah.txt', StringIO.new('blah'))
    v.add_file('hello/whatever.txt', StringIO.new('whatever'))
    assert v.commit.present?
    assert v.file_exists?('blah.txt')
    assert v.file_exists?('hello/whatever.txt')
    assert_equal 'blah', v.file_contents('blah.txt')
    assert_equal 'whatever', v.file_contents('hello/whatever.txt')
    assert_not_empty v.blobs
  end

  test 'cannot add file to immutable version' do
    repo = Factory(:local_repository)
    workflow = repo.resource

    v = workflow.git_versions.create!(mutable: false)
    assert_equal 'This Workflow', v.title
    refute v.mutable?
    commit = v.commit
    blobs = v.blobs

    assert_raise(GitVersion::ImmutableVersionException) do
      v.add_file('blah.txt', StringIO.new('blah'))
    end

    assert_equal commit, v.commit
    assert_equal blobs, v.blobs
  end

  test 'automatically init local git repo' do
    w = Factory(:workflow)
    v = w.git_versions.create

    assert v.git_repository
    assert w.local_git_repository
    assert_equal w.local_git_repository, v.git_repository
  end

  test 'automatically link existing remote git repos' do
    w = Factory(:workflow, git_version_attributes: { remote: 'https://git.git/git.git' })
    w2 = Factory(:workflow, git_version_attributes: { remote: 'https://git.git/git.git' })

    assert_nil w.local_git_repository
    assert_nil w2.local_git_repository
    assert_equal w.latest_git_version.git_repository, w2.latest_git_version.git_repository
  end

  test 'create git version on create' do
    # Make sure remote repo exists
    Factory(:workflow, git_version_attributes: { remote: 'https://git.git/git.git' })

    assert_difference('GitVersion.count', 1) do
      assert_no_difference('GitRepository.count') do
        w = Factory(:workflow, title: 'Test', description: 'Testy', git_version_attributes: {
            ref: 'refs/heads/master',
            remote: 'https://git.git/git.git'
        })
        assert_equal 1, w.git_versions.count

        v = w.git_versions.last
        assert_equal 'Test', v.title
        assert_equal 'Testy', v.description
        assert_equal 'https://git.git/git.git', v.git_repository.remote
        assert_equal 'refs/heads/master', v.ref
      end
    end
  end

  test 'create git version with local repo and defaults on create' do
    skip "Not doing this for now"
    assert_difference('GitVersion.count', 1) do
      assert_difference('GitRepository.count', 1) do
        w = Factory(:workflow, title: 'Test', description: 'Testy')
        assert_equal 1, w.git_versions.count

        v = w.git_versions.last
        assert_equal 'Test', v.title
        assert_equal 'Testy', v.description
        assert_nil v.git_repository.remote
        assert_equal 'refs/heads/master', v.ref, 'Ref should be master by default'
        assert_equal 'Version 1', v.name
      end
    end
  end

  test 'resolve refs' do
    remote = Factory(:remote_repository)
    workflow = Factory(:workflow, git_version_attributes: { git_repository_id: remote.id })
    # v = workflow.git_versions.create!(mutable: false)

    # assert_equal '068cecdfce022aa98532026957a0c9519402e156', v.commit
    v = workflow.git_versions.create!(remote: remote.remote, ref: 'refs/remotes/origin/main')
    assert_equal 'b6312caabe582d156dd351fab98ce78356c4b74c', v.commit
    v = workflow.git_versions.create!(remote: remote.remote, ref: 'refs/tags/v0.01')
    assert_equal '3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf', v.commit
  end

  test 'remove file' do
    workflow = Factory(:workflow)
    repo = Factory(:local_repository, resource: workflow)

    v = workflow.git_versions.create!(mutable: true)
    old_commit = v.commit
    old_blob_count = v.blobs.length
    assert v.file_exists?('diagram.png')

    v.remove_file('diagram.png')

    v.reload

    refute v.file_exists?('diagram.png')
    assert_equal old_blob_count - 1, v.blobs.count
    assert_not_equal old_commit, v.commit
  end

  test 'rename file' do
    workflow = Factory(:workflow)
    repo = Factory(:local_repository, resource: workflow)

    v = workflow.git_versions.create!(mutable: true)
    old_commit = v.commit
    assert v.file_exists?('diagram.png')
    refute v.file_exists?('images/lookatme.png')

    v.move_file('diagram.png', 'images/lookatme.png')

    v.reload

    refute v.file_exists?('diagram.png')
    assert v.file_exists?('images/lookatme.png')
    assert_not_equal old_commit, v.commit
  end

  test 'sync attributes' do
    repo = Factory(:unlinked_local_repository)
    workflow = Factory(:workflow, description: 'Test ABC', git_version_attributes: { git_repository_id: repo.id })
    v = workflow.latest_git_version

    assert_equal 'Test ABC', workflow.description
    assert_equal 'Test ABC', v.description

    disable_authorization_checks { workflow.update_attribute(:description, 'Test 123') }

    assert_equal 'Test 123', workflow.reload.description
    assert_equal 'Test 123', v.reload.description
  end

  test 'cannot link to existing local repository' do
    repo = Factory(:local_repository)
    gv = Factory.build(:git_version, git_repository_id: repo.id)
    refute gv.save
    assert gv.errors.added?(:git_repository, 'already linked to another resource')
  end
end
