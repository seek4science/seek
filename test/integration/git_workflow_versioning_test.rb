require 'test_helper'

class GitWorkflowVersioningTest < ActionDispatch::IntegrationTest
  test 'can register a new version for a remote git workflow' do
    workflow = FactoryBot.create(:remote_git_workflow)
    repo = workflow.latest_git_version.git_repository
    person = workflow.contributor

    repo_count = Git::Repository.count
    workflow_count = Workflow.count
    version_count = Git::Version.count
    annotation_count = Git::Annotation.count

    login_as(person.user)

    assert_no_enqueued_jobs(only: RemoteGitFetchJob) do
      assert_no_difference('Git::Repository.count') do
        assert_no_difference('Task.count') do
          get new_git_version_workflow_path(workflow.id)

          assert_response :success
          assert_select 'input.form-control[value=?]', repo.remote
          assert_select 'form[action=?]', create_version_from_git_workflow_path(workflow.id, anchor: 'new-remote-version')
          assert_select 'form[action=?]', create_version_from_git_workflow_path(workflow.id, anchor: 'new-local-version'), count: 0
        end
      end
    end

    assert_enqueued_jobs(1, only: RemoteGitFetchJob) do
      assert_no_difference('Git::Repository.count') do
        assert_difference('Task.count', 1) do
          post create_version_from_git_workflow_path, params: {
            id: workflow.id,
            workflow: { git_version_attributes: { git_repository_id: repo.id } } }

          assert_response :success
          assert_select '#repo-ref-form'
          assert_select 'form[action=?]', create_version_from_git_workflow_path(workflow.id)
        end
      end
    end

    # Simulate repository being fetched
    repo.remote_git_fetch_task.update_column(:status, Task::STATUS_DONE)
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'fixture-workflow', '_git', '.'), File.join(repo.local_path, '.git'))

    post create_version_from_git_workflow_path, params: {
        id: workflow.id,
        workflow: { git_version_attributes: { git_repository_id: repo.id, ref: 'refs/tags/v0.01' } } }

    # Should go straight to metadata page since main workflow path is the same as the last version.
    assert_select 'input[name="workflow[title]"]', count: 1

    assert_no_difference('Workflow.count') do
      assert_difference('Git::Version.count', 1) do
        assert_difference('Git::Annotation.count', 1) do
          post create_version_metadata_workflow_path, params: {
            id: workflow.id,
            workflow: {
              workflow_class_id: workflow.workflow_class_id,
              title: 'blabla',
              project_ids: [person.projects.first.id],
              git_version_attributes: {
                root_path: '/',
                git_repository_id: repo.id,
                commit: '3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf',
                ref: 'refs/tags/v0.01',
                main_workflow_path: 'concat_two_files.ga'
              }
            }
          } # Should go to workflow page...
        end
      end
    end

    assert_redirected_to workflow_path(assigns(:workflow))

    assert_equal '3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf', assigns(:workflow).latest_git_version.commit
    assert_equal 'refs/tags/v0.01', assigns(:workflow).latest_git_version.ref
    assert assigns(:workflow).latest_git_version.git_repository.remote?
    assert_nil assigns(:workflow).latest_git_version.git_repository.resource

    # Check there wasn't anything extra created in the whole flow...
    assert_equal repo_count, Git::Repository.count
    assert_equal workflow_count, Workflow.count
    assert_equal version_count + 1, Git::Version.count
    assert_equal annotation_count + 1, Git::Annotation.count
  end

  test 'can freeze and register a new development version for a local git workflow' do
    workflow = FactoryBot.create(:local_git_workflow)
    person = workflow.contributor
    version = workflow.latest_git_version.version

    repo_count = Git::Repository.count
    workflow_count = Workflow.count
    version_count = Git::Version.count
    annotation_count = Git::Annotation.count

    login_as(person.user)

    assert workflow.latest_git_version.mutable?

    get workflow_git_freeze_preview_path(workflow.id, version: version)

    assert_response :success

    post workflow_git_freeze_path(workflow.id, version: version), params: {
      git_version: {
        name: 'Version A',
        comment: 'Finished the stuff'
      }
    }

    assert_redirected_to workflow_path(workflow)
    follow_redirect!

    assert_equal 'Version A', workflow.find_git_version(1).name
    assert_equal 'Finished the stuff', workflow.find_git_version(1).comment

    refute workflow.latest_git_version.reload.mutable?

    assert_enqueued_jobs(0, only: RemoteGitFetchJob) do
      assert_no_difference('Git::Repository.count') do
        assert_no_difference('Git::Version.count') do
          assert_no_difference('Git::Annotation.count') do
            assert_no_difference('Task.count') do
              get new_git_version_workflow_path(workflow.id)

              assert_response :success
              assert_select 'form[action=?]', create_version_from_git_workflow_path(workflow.id, anchor: 'new-local-version')
              assert_select 'form[action=?]', create_version_from_git_workflow_path(workflow.id, anchor: 'new-remote-version')
            end
          end
        end
      end
    end

    assert_enqueued_jobs(0, only: RemoteGitFetchJob) do
      assert_no_difference('Git::Repository.count') do
        assert_difference('Git::Version.count', 1) do
          assert_difference('Git::Annotation.count', 2) do
            assert_no_difference('Task.count') do
              post create_version_from_git_workflow_path, params: { id: workflow.id,
                workflow: { git_version_attributes: { git_repository_id: workflow.local_git_repository.id } } }


              assert_redirected_to workflow_path(workflow)
            end
          end
        end
      end
    end

    assert_equal version + 1, workflow.reload.latest_git_version.version
    assert_equal 'Version 2', workflow.latest_git_version.name
    ann1 = workflow.find_git_version(1).git_annotations.map { |a| { key: a.key, path: a.path } }
    ann2 = workflow.find_git_version(2).git_annotations.map { |a| { key: a.key, path: a.path } }
    assert_equal ann1, ann2, 'Annotations should have been copied'

    # Check there wasn't anything extra created in the whole flow...
    assert_equal repo_count, Git::Repository.count
    assert_equal workflow_count, Workflow.count
    assert_equal version_count + 1, Git::Version.count
    assert_equal annotation_count + 2, Git::Annotation.count
  end


  test 'can convert a local git workflow to a remote one' do
    workflow = FactoryBot.create(:local_git_workflow)
    person = workflow.contributor
    version = workflow.latest_git_version.version

    repo_count = Git::Repository.count
    workflow_count = Workflow.count
    version_count = Git::Version.count
    annotation_count = Git::Annotation.count

    login_as(person.user)

    assert workflow.latest_git_version.mutable?

    get workflow_git_freeze_preview_path(workflow.id, version: version)

    assert_response :success

    post workflow_git_freeze_path(workflow.id, version: version), params: {
      git_version: {
        name: 'Version A',
        comment: 'Finished the stuff'
      }
    }

    assert_redirected_to workflow_path(workflow)
    follow_redirect!

    assert_equal 'Version A', workflow.find_git_version(1).name
    assert_equal 'Finished the stuff', workflow.find_git_version(1).comment

    refute workflow.latest_git_version.reload.mutable?

    assert_enqueued_jobs(0, only: RemoteGitFetchJob) do
      assert_no_difference('Git::Repository.count') do
        assert_no_difference('Git::Version.count') do
          assert_no_difference('Git::Annotation.count') do
            assert_no_difference('Task.count') do
              get new_git_version_workflow_path(workflow.id)

              assert_response :success
              assert_select 'form[action=?]', create_version_from_git_workflow_path(workflow.id, anchor: 'new-local-version')
              assert_select 'form[action=?]', create_version_from_git_workflow_path(workflow.id, anchor: 'new-remote-version')
            end
          end
        end
      end
    end

    assert_enqueued_jobs(1, only: RemoteGitFetchJob) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Task.count', 1) do
          post create_version_from_git_workflow_path, params: {
            id: workflow.id,
            workflow: { git_version_attributes: { remote: 'http://somewhere.com' } } }

          assert_response :success
          assert_select '#repo-ref-form'
          assert_select 'form[action=?]', create_version_from_git_workflow_path(workflow.id)
        end
      end
    end

    repo = Git::Repository.last

    # Simulate repository being fetched
    repo.remote_git_fetch_task.update_column(:status, Task::STATUS_DONE)
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'fixture-workflow', '_git', '.'), File.join(repo.local_path, '.git'))

    post create_version_from_git_workflow_path, params: {
      id: workflow.id,
      workflow: { git_version_attributes: { git_repository_id: repo.id, ref: 'refs/tags/v0.01' } } }

    # Should go straight to metadata page since main workflow path is the same as the last version.
    assert_select 'input[name="workflow[title]"]', count: 1

    assert_no_difference('Workflow.count') do
      assert_difference('Git::Version.count', 1) do
        assert_difference('Git::Annotation.count', 1) do
          post create_version_metadata_workflow_path, params: {
            id: workflow.id,
            workflow: {
              workflow_class_id: workflow.workflow_class_id,
              title: 'blabla',
              project_ids: [person.projects.first.id],
              git_version_attributes: {
                root_path: '/',
                git_repository_id: repo.id,
                commit: '3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf',
                ref: 'refs/tags/v0.01',
                main_workflow_path: 'concat_two_files.ga'
              }
            }
          } # Should go to workflow page...
        end
      end
    end

    assert_redirected_to workflow_path(assigns(:workflow))

    assert_equal '3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf', assigns(:workflow).latest_git_version.commit
    assert_equal 'refs/tags/v0.01', assigns(:workflow).latest_git_version.ref
    assert assigns(:workflow).latest_git_version.git_repository.remote?
    assert_nil assigns(:workflow).latest_git_version.git_repository.resource

    # Check there wasn't anything extra created in the whole flow...
    assert_equal repo_count + 1, Git::Repository.count
    assert_equal workflow_count, Workflow.count
    assert_equal version_count + 1, Git::Version.count
    assert_equal annotation_count + 1, Git::Annotation.count
  end

  private

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end