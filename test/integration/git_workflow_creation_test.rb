require 'test_helper'

class GitWorkflowCreationTest < ActionDispatch::IntegrationTest

  test 'can register a remote git repository as a workflow' do
    repo_count = Git::Repository.count
    workflow_count = Workflow.count
    version_count = Git::Version.count
    annotation_count = Git::Annotation.count

    person = Factory(:person)
    galaxy = WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class)
    login_as(person.user)

    get new_workflow_path

    assert_enqueued_jobs(1, only: RemoteGitFetchJob) do
      assert_difference('Git::Repository.count', 1) do
        assert_difference('Task.count', 1) do
          post git_repositories_path, params: { resource_type: 'workflow', remote: 'https://github.com/seek4science/workflow-test-fixture.git' }

          assert_redirected_to select_ref_git_repository_path(assigns(:git_repository), resource_type: 'workflow')
        end
      end
    end

    follow_redirect!

    repo = assigns(:git_repository)
    assert repo.remote_git_fetch_task&.in_progress?
    assert_select '#fetching-status'

    # Simulate repository being fetched
    repo.remote_git_fetch_task.update_column(:status, Task::STATUS_DONE)
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'fixture-workflow', '_git', '.'), File.join(repo.local_path, '.git'))

    get select_ref_git_repository_path(repo, resource_type: 'workflow') # Should get ref selection page...
    assert_select '#fetching-status', count: 0

    post create_from_git_workflows_path, params: {
        workflow: { git_version_attributes: { git_repository_id: repo.id, ref: 'refs/remotes/origin/main' } } }# Should go to path selection page..
    assert_select 'input[data-role="seek-git-path-input"]', count: 3
    assert_select 'input[name="workflow[title]"]', count: 0

    post create_from_git_workflows_path, params: {
        workflow: {
            workflow_class_id: galaxy.id,
            git_version_attributes: {
                git_repository_id: repo.id, ref: 'refs/remotes/origin/main',
                main_workflow_path: 'concat_two_files.ga',
                diagram_path: 'diagram.png',
                workflow_class_id: galaxy.id
            }
        }
    } # Should go to metadata page...

    assert_select 'input[name="workflow[title]"]', count: 1

    assert_difference('Workflow.count', 1) do
      assert_difference('Git::Version.count', 1) do
        assert_difference('Git::Annotation.count', 2) do
          post create_metadata_workflows_path, params: { workflow: {
                                                  workflow_class_id: galaxy.id,
                                                  title: 'blabla',
                                                  project_ids: [person.projects.first.id],
                                                  git_version_attributes: {
                                                      root_path: '/',
                                                      git_repository_id: repo.id,
                                                      ref: 'refs/remotes/origin/main',
                                                      main_workflow_path: 'concat_two_files.ga',
                                                      diagram_path: 'diagram.png'
                                                  }
                                              }
          } # Should go to workflow page...
        end
      end
    end

    assert_redirected_to workflow_path(assigns(:workflow))

    assert assigns(:workflow).latest_git_version.commit.present?
    assert_equal 'refs/remotes/origin/main', assigns(:workflow).latest_git_version.ref
    assert assigns(:workflow).latest_git_version.git_repository.remote?
    assert_nil assigns(:workflow).latest_git_version.git_repository.resource

    # Check there wasn't anything extra created in the whole flow...
    assert_equal repo_count + 1, Git::Repository.count
    assert_equal workflow_count + 1, Workflow.count
    assert_equal version_count + 1, Git::Version.count
    assert_equal annotation_count + 2, Git::Annotation.count
  end

  test 'can upload local files to create a local git repository for a workflow' do
    repo_count = Git::Repository.count
    workflow_count = Workflow.count
    version_count = Git::Version.count
    annotation_count = Git::Annotation.count

    person = Factory(:person)
    cwl = WorkflowClass.find_by_key('cwl') || Factory(:cwl_workflow_class)
    login_as(person.user)

    get new_workflow_path

    assert_enqueued_jobs(0) do
      assert_difference('Git::Repository.count', 1) do
        assert_no_difference('Task.count') do
          post create_from_files_workflows_path, params: {
              ro_crate: {
                main_workflow: { data: fixture_file_upload('files/workflows/rp2-to-rp2path-packed.cwl', 'text/plain') },
                diagram: { data: fixture_file_upload('files/file_picture.png', 'image/png') }
              },
              workflow_class_id: cwl.id
          } # Should go to metadata page...
        end
      end
    end

    repo = assigns(:workflow).git_version.git_repository
    assert_select 'input[name="workflow[title]"]', count: 1

    assert_difference('Workflow.count', 1) do
      assert_difference('Git::Version.count', 1) do
        assert_difference('Git::Annotation.count', 2) do
          post create_metadata_workflows_path, params: {
              workflow: {
                  workflow_class_id: cwl.id,
                  title: 'blabla',
                  project_ids: [person.projects.first.id],
                  git_version_attributes: {
                      root_path: '/',
                      git_repository_id: repo.id,
                      ref: 'refs/heads/master',
                      main_workflow_path: 'rp2-to-rp2path-packed.cwl',
                      diagram_path: 'file_picture.png'
                  }
              }
          } # Should go to workflow page...
        end
      end
    end

    assert_redirected_to workflow_path(assigns(:workflow))

    assert assigns(:workflow).latest_git_version.commit.present?
    assert_equal 'refs/heads/master', assigns(:workflow).latest_git_version.ref
    refute assigns(:workflow).latest_git_version.git_repository.remote?
    assert_equal assigns(:workflow), assigns(:workflow).latest_git_version.git_repository.resource

    # Check there wasn't anything extra created in the whole flow...
    assert_equal repo_count + 1, Git::Repository.count
    assert_equal workflow_count + 1, Workflow.count
    assert_equal version_count + 1, Git::Version.count
    assert_equal annotation_count + 2, Git::Annotation.count
  end

  test 'can upload local RO-Crate to create a local git repository for a workflow' do
    repo_count = Git::Repository.count
    workflow_count = Workflow.count
    version_count = Git::Version.count
    annotation_count = Git::Annotation.count

    person = Factory(:person)
    nextflow = WorkflowClass.find_by_key('nextflow') || Factory(:nextflow_workflow_class)
    login_as(person.user)

    get new_workflow_path

    assert_enqueued_jobs(0) do
      assert_difference('Git::Repository.count', 1) do
        assert_no_difference('Task.count') do
          post create_from_ro_crate_workflows_path, params: {
              ro_crate: { data: fixture_file_upload('files/workflows/ro-crate-nf-core-ampliseq.crate.zip', 'application/zip') }
          } # Should go to metadata page...
        end
      end
    end

    repo = assigns(:workflow).git_version.git_repository
    assert_select 'input[name="workflow[title]"]', count: 1

    assert_difference('Workflow.count', 1) do
      assert_difference('Git::Version.count', 1) do
        assert_difference('Git::Annotation.count', 1) do
          post create_metadata_workflows_path, params: {
              workflow: {
                  workflow_class_id: nextflow.id,
                  title: 'blabla',
                  project_ids: [person.projects.first.id],
                  git_version_attributes: {
                      root_path: '/',
                      git_repository_id: repo.id,
                      ref: 'refs/heads/master',
                      main_workflow_path: 'main.nf'
                  }
              }
          } # Should go to workflow page...
        end
      end
    end

    assert_redirected_to workflow_path(assigns(:workflow))

    assert assigns(:workflow).latest_git_version.commit.present?
    assert_equal 'refs/heads/master', assigns(:workflow).latest_git_version.ref
    refute assigns(:workflow).latest_git_version.git_repository.remote?
    assert_equal assigns(:workflow), assigns(:workflow).latest_git_version.git_repository.resource

    # Check there wasn't anything extra created in the whole flow...
    assert_equal repo_count + 1, Git::Repository.count
    assert_equal workflow_count + 1, Workflow.count
    assert_equal version_count + 1, Git::Version.count
    assert_equal annotation_count + 1, Git::Annotation.count
  end

  private

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end