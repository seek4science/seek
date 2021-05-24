require 'test_helper'

class GitWorkflowCreationTest < ActionDispatch::IntegrationTest

  test 'can register a remote git repository as a workflow' do
    repo_count = GitRepository.count
    workflow_count = Workflow.count
    version_count = GitVersion.count
    annotation_count = GitAnnotation.count

    person = Factory(:person)
    galaxy = WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class)
    login_as(person.user)

    get new_workflow_path

    assert_enqueued_jobs(1, only: RemoteGitFetchJob) do
      assert_difference('GitRepository.count', 1) do
        assert_difference('Task.count', 1) do
          post git_repositories_path(resource_type: 'workflow', remote: 'https://github.com/seek4science/workflow-test-fixture.git')

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

    post create_from_git_workflows_path(git_repository_id: repo.id, ref: 'refs/remotes/origin/main') # Should go to path selection page..
    assert_select 'input[data-role="seek-git-path-input"]', count: 3
    assert_select 'input[name="workflow[title]"]', count: 0

    post create_from_git_workflows_path(git_repository_id: repo.id, ref: 'refs/remotes/origin/main',
                                        main_workflow_path: 'concat_two_files.ga',
                                        diagram_path: 'diagram.png',
                                        workflow_class_id: galaxy.id) # Should go to metadata page...

    assert_select 'input[name="workflow[title]"]', count: 1

    assert_difference('Workflow.count', 1) do
      assert_difference('GitVersion.count', 1) do
        assert_difference('GitAnnotation.count', 2) do
          post create_metadata_workflows_path(git_repository_id: repo.id, ref: 'refs/remotes/origin/main',
                                              workflow: {
                                                  workflow_class_id: galaxy.id,
                                                  title: 'blabla',
                                                  project_ids: [person.projects.first],
                                                  git_version_attributes: {
                                                      root_path: '/',
                                                      git_repository_id: repo.id,
                                                      ref: 'refs/remotes/origin/main',
                                                      git_annotations_attributes: {
                                                          '0' => { path: 'concat_two_files.ga', key: 'main_workflow' },
                                                          '1' => { path: 'diagram.png', key: 'diagram' }
                                                      }
                                                  }
                                              }) # Should go to workflow page...
          assert_redirected_to workflow_path(assigns(:workflow))
        end
      end
    end

    # Check there wasn't anything extra created in the whole flow...
    assert_equal repo_count + 1, GitRepository.count
    assert_equal workflow_count + 1, Workflow.count
    assert_equal version_count + 1, GitVersion.count
    assert_equal annotation_count + 2, GitAnnotation.count
  end

  private

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end