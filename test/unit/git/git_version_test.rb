require 'test_helper'

class GitVersionTest < ActiveSupport::TestCase
  test 'git version default name' do
    workflow = FactoryBot.create(:local_git_workflow)
    assert_equal 'Version 1', workflow.git_version.name
  end

  test 'create new git version' do
    workflow = FactoryBot.create(:local_git_workflow)
    assert_equal 1, workflow.version
    assert_equal 1, workflow.latest_git_version.version
    assert_equal 1, workflow.git_versions.count
    disable_authorization_checks do
      assert workflow.latest_git_version.next_version.save
    end
    assert_equal 2, workflow.version
    assert_equal 2, workflow.latest_git_version.version
    assert_equal 2, workflow.git_versions.count
  end

  test 'lock version' do
    repo = FactoryBot.create(:local_repository)
    workflow = repo.resource

    v = disable_authorization_checks do
      workflow.save_as_new_git_version(name: 'version 1.0.0', ref: 'refs/heads/master', mutable: true)
    end
    assert_equal 'This Workflow', v.title
    refute v.git_base.tags['version-1.0.0']
    assert v.mutable?

    disable_authorization_checks { v.lock }
    workflow.update_column(:title, 'Something else')
    new_class = WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class)
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
    workflow = FactoryBot.create(:workflow)
    repo = FactoryBot.create(:blank_repository, resource: workflow)

    v = disable_authorization_checks { workflow.git_versions.create!(mutable: true) }
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

  test 'change git author' do
    workflow = FactoryBot.create(:workflow)
    repo = FactoryBot.create(:blank_repository, resource: workflow)

    v = disable_authorization_checks { workflow.git_versions.create!(mutable: true) }
    assert_equal 'This Workflow', v.title
    assert v.mutable?
    assert v.commit.blank?
    assert_empty v.blobs

    User.with_current_user(workflow.contributor.user) do
      v.add_file('blah.txt', StringIO.new('blah'))
    end

    author = repo.git_base.lookup(v.commit).author

    assert_equal workflow.contributor.name, author[:name]
    assert_equal workflow.contributor.email, author[:email]

    v.with_git_author(email: 'bob@example.com', name: 'bob', time: 10.years.ago.to_time) do
      v.add_file('blah2.txt', StringIO.new('blah'))
    end

    author = repo.git_base.lookup(v.commit).author

    assert_equal 'bob', author[:name]
    assert_equal 'bob@example.com', author[:email]
    assert author[:time] < 9.years.ago.to_time
  end

  test 'cannot add file to immutable version' do
    repo = FactoryBot.create(:local_repository)
    workflow = repo.resource

    v = disable_authorization_checks { workflow.git_versions.create!(mutable: false) }
    assert_equal 'This Workflow', v.title
    refute v.mutable?
    commit = v.commit
    blobs = v.blobs

    assert_raise(Git::ImmutableVersionException) do
      v.add_file('blah.txt', StringIO.new('blah'))
    end

    assert_equal commit, v.commit
    assert_equal blobs, v.blobs
  end

  test 'automatically init local git repo' do
    w = FactoryBot.create(:workflow)
    disable_authorization_checks do
      v = w.git_versions.create
      assert v.git_repository
      assert w.local_git_repository
      assert_equal w.local_git_repository, v.git_repository
    end
  end

  test 'automatically link existing remote git repos' do
    w = FactoryBot.create(:workflow, git_version_attributes: { remote: 'https://git.git/git.git' })
    w2 = FactoryBot.create(:workflow, git_version_attributes: { remote: 'https://git.git/git.git' })

    assert_nil w.local_git_repository
    assert_nil w2.local_git_repository
    assert_equal w.latest_git_version.git_repository, w2.latest_git_version.git_repository
  end

  test 'create git version on create' do
    # Make sure remote repo exists
    FactoryBot.create(:workflow, git_version_attributes: { remote: 'https://git.git/git.git' })

    assert_difference('Git::Version.count', 1) do
      assert_no_difference('Git::Repository.count') do
        w = FactoryBot.create(:workflow, title: 'Test', description: 'Testy', git_version_attributes: {
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
    assert_difference('Git::Version.count', 1) do
      assert_difference('Git::Repository.count', 1) do
        w = FactoryBot.create(:workflow, title: 'Test', description: 'Testy')
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
    remote = FactoryBot.create(:remote_repository)
    workflow = FactoryBot.create(:workflow, git_version_attributes: { git_repository_id: remote.id })

    v = disable_authorization_checks { workflow.git_versions.create!(remote: remote.remote, ref: 'refs/remotes/origin/main') }
    assert_equal '94ae9926a824ebe809a9e9103cbdb1d5c5f98608', v.commit
    v = disable_authorization_checks { workflow.git_versions.create!(remote: remote.remote, ref: 'refs/tags/v0.01') }
    assert_equal '3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf', v.commit
    v = disable_authorization_checks { workflow.git_versions.create!(remote: remote.remote, ref: 'refs/tags/v0.02') }
    assert_equal '94ae9926a824ebe809a9e9103cbdb1d5c5f98608', v.commit
  end

  test 'remove file' do
    workflow = FactoryBot.create(:local_git_workflow)
    v = workflow.latest_git_version

    old_commit = v.commit
    old_blob_count = v.blobs.length
    assert v.file_exists?('diagram.png')

    v.remove_file('diagram.png')

    refute v.file_exists?('diagram.png')
    assert_equal old_blob_count - 1, v.blobs.count
    assert_not_equal old_commit, v.commit
  end

  test 'rename file' do
    workflow = FactoryBot.create(:local_git_workflow)

    v = workflow.latest_git_version
    old_commit = v.commit
    assert v.file_exists?('diagram.png')
    refute v.file_exists?('images/lookatme.png')

    v.move_file('diagram.png', 'images/lookatme.png')

    refute v.file_exists?('diagram.png')
    assert v.file_exists?('images/lookatme.png')
    assert_not_equal old_commit, v.commit
  end

  test 'sync attributes' do
    repo = FactoryBot.create(:unlinked_local_repository)
    workflow = FactoryBot.create(:workflow, description: 'Test ABC', git_version_attributes: { git_repository_id: repo.id })
    v = workflow.latest_git_version

    assert_equal 'Test ABC', workflow.description
    assert_equal 'Test ABC', v.description

    disable_authorization_checks { workflow.update_attribute(:description, 'Test 123') }

    assert_equal 'Test 123', workflow.reload.description
    assert_equal 'Test 123', v.reload.description
  end

  test 'cannot link to existing local repository' do
    repo = FactoryBot.create(:local_repository)
    gv = FactoryBot.build(:git_version, git_repository_id: repo.id)
    refute gv.save
    assert gv.errors.added?(:git_repository, 'already linked to another resource')
  end

  test 'authorization' do
    gv = FactoryBot.create(:git_version)

    refute gv.can_view?
    refute gv.resource.can_view?
    refute gv.can_download?
    refute gv.resource.can_download?
    refute gv.can_edit?
    refute gv.resource.can_edit?
    refute gv.can_manage?
    refute gv.resource.can_manage?
    refute gv.can_delete?
    refute gv.resource.can_delete?

    disable_authorization_checks { gv.resource.policy = FactoryBot.create(:public_policy); gv.resource.save! }

    assert gv.can_view?
    assert gv.resource.can_view?
    assert gv.can_download?
    assert gv.resource.can_download?
    assert gv.can_edit?
    assert gv.resource.can_edit?
    assert gv.can_manage?
    assert gv.resource.can_manage?
    assert gv.can_delete?
    assert gv.resource.can_delete?
  end

  test 'attributes synced for factory' do
    gv = FactoryBot.create(:git_version)
    r = gv.resource
    keys = r.attributes.keys.map(&:to_sym) - [:id, :created_at, :updated_at, :contributor_id]
    keys.each do |k|
      if r[k].nil?
        assert_nil gv.send(k), "#{k} did not match"
      else
        assert_equal r[k], gv.send(k), "#{k} did not match"
      end
    end
  end

  test 'can initialize next version of an immutable git_version' do
    gv = FactoryBot.create(:git_version)
    disable_authorization_checks { gv.lock }

    next_ver = gv.next_version

    assert_includes gv.resource.git_versions, next_ver
    refute next_ver.persisted?
    assert_equal gv.version + 1, next_ver.version
    assert_equal "Version #{gv.version + 1}", next_ver.name
    assert next_ver[:comment].blank?
    assert_equal gv.resource_attributes['title'], next_ver.resource_attributes['title']
    assert_equal gv.commit, next_ver.commit
    assert_equal gv.git_repository, next_ver.git_repository
  end

  test 'can handle unusual paths' do
    workflow = FactoryBot.create(:workflow)
    repo = FactoryBot.create(:blank_repository, resource: workflow)

    v = disable_authorization_checks { workflow.git_versions.create!(mutable: true) }
    assert_equal 'This Workflow', v.title
    assert v.mutable?
    assert v.commit.blank?
    assert_empty v.blobs

    assert_raise(Git::InvalidPathException) do
      v.add_file('///', StringIO.new('blah'))
    end

    assert_raise(Git::InvalidPathException) do
      v.add_file('something/', StringIO.new('blah'))
    end

    assert_nothing_raised do
      v.add_file('?&&?&&?&&&?', StringIO.new('blah'))
    end

    assert_nothing_raised do
      v.add_file('     ', StringIO.new('blah'))
    end

    assert v.reload.commit.present?
    refute v.file_exists?('///')
    refute v.file_exists?('something/')
    assert v.file_exists?('?&&?&&?&&&?')
    assert v.file_exists?('     ')
  end

  test 'valid paths are rejected when committed with invalid paths' do
    workflow = FactoryBot.create(:workflow)
    repo = FactoryBot.create(:blank_repository, resource: workflow)

    v = disable_authorization_checks { workflow.git_versions.create!(mutable: true) }
    assert_equal 'This Workflow', v.title
    assert v.mutable?
    assert v.commit.blank?
    assert_empty v.blobs

    assert_raise(Git::InvalidPathException) do
      v.add_files([['valid_path', StringIO.new('blah')], ['../../../secrets', StringIO.new('blah')]])
    end

    refute v.file_exists?('valid_path'), 'valid_path should not have been committed as it was bundled with an invalid path.'
    refute v.file_exists?('../../../secrets')
    assert v.reload.commit.blank?
  end

  test 'add remote file' do
    workflow = FactoryBot.create(:workflow)
    repo = FactoryBot.create(:blank_repository, resource: workflow)

    v = disable_authorization_checks { workflow.git_versions.create!(mutable: true) }
    assert_equal 'This Workflow', v.title
    assert v.mutable?
    assert v.commit.blank?
    assert_empty v.blobs
    assert_empty v.remote_sources

    assert_difference('Git::Annotation.count', 1) do
      assert_enqueued_jobs(1, only: RemoteGitContentFetchingJob) do
        v.add_remote_file('blah.txt', 'http://internet.internet/file')
        disable_authorization_checks { v.save! }
      end
    end

    assert v.reload.commit.present?
    assert_equal 'http://internet.internet/file', v.remote_sources['blah.txt']
    assert v.file_exists?('blah.txt')
    assert_equal '', v.file_contents('blah.txt')
    assert_not_empty v.blobs
    refute v.get_blob('blah.txt').fetched?

    # Fetch
    mock_remote_file "#{Rails.root}/test/fixtures/files/little_file.txt", 'http://internet.internet/file'
    v.fetch_remote_file('blah.txt')
    assert_equal 'http://internet.internet/file', v.remote_sources['blah.txt']
    assert_equal 'little file', v.file_contents('blah.txt')
    assert v.get_blob('blah.txt').fetched?
  end

  test 'add remote file without fetch job' do
    workflow = FactoryBot.create(:workflow)
    repo = FactoryBot.create(:blank_repository, resource: workflow)

    v = disable_authorization_checks { workflow.git_versions.create!(mutable: true) }
    assert_equal 'This Workflow', v.title
    assert v.mutable?
    assert v.commit.blank?
    assert_empty v.blobs
    assert_empty v.remote_sources

    assert_difference('Git::Annotation.count', 1) do
      assert_no_enqueued_jobs(only: RemoteGitContentFetchingJob) do
        v.add_remote_file('blah.txt', 'http://internet.internet/file', fetch: false)
        disable_authorization_checks { v.save! }
      end
    end

    assert v.reload.commit.present?
    assert_equal 'http://internet.internet/file', v.remote_sources['blah.txt']
    assert v.file_exists?('blah.txt')
    assert_equal '', v.file_contents('blah.txt')
    assert_not_empty v.blobs
  end

  test 'do not add remote file with inaccessible URL' do
    workflow = FactoryBot.create(:workflow)
    repo = FactoryBot.create(:blank_repository, resource: workflow)

    v = disable_authorization_checks { workflow.git_versions.create!(mutable: true) }
    assert_equal 'This Workflow', v.title
    assert v.mutable?
    assert v.commit.blank?
    assert_empty v.blobs
    assert_empty v.remote_sources

    assert_difference('Git::Annotation.count', 0) do
      assert_enqueued_jobs(0, only: RemoteGitContentFetchingJob) do
        assert_raise(URI::InvalidURIError) do
          v.add_remote_file('blah.txt', '/mypc/files/something.txt')
        end
      end
    end

    refute v.reload.commit.present?
    assert_empty v.blobs
    assert_empty v.remote_sources
  end

  test 'empty?' do
    workflow = FactoryBot.create(:empty_git_workflow)
    assert workflow.git_version.empty?

    workflow.git_version.add_file('folder/blah.txt', StringIO.new('blah'))
    refute workflow.git_version.empty?
  end

  test 'get blob' do
    gv = FactoryBot.create(:ro_crate_git_workflow).git_version

    blob = gv.get_blob('sort-and-change-case.ga')
    assert blob
    assert_equal 3862, blob.size

    nested_blob = gv.get_blob('test/test1/sort-and-change-case-test.yml')
    assert nested_blob
    assert_equal 150, nested_blob.size

    assert_nil gv.get_blob('banana')
  end

  test 'get tree' do
    gv = FactoryBot.create(:ro_crate_git_workflow).git_version

    root = gv.tree
    assert_equal '/', root.path
    assert_equal 18846, root.total_size

    tree = gv.get_tree('test')
    assert_equal 288, tree.total_size

    nested_tree = gv.get_tree('test/test1')
    assert_equal 288, nested_tree.total_size

    assert_nil gv.get_tree('banana')
  end
end
