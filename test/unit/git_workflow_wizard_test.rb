
require 'test_helper'

class GitWorkflowWizardTest < ActiveSupport::TestCase
  test 'create repo and direct to select_ref if remote given but ref missing' do
    assert_nil Git::Repository.find_by_remote('https://github.com/seek4science/workflow-test-fixture.git')

    params = {
      workflow: {
        git_version_attributes: {
          remote: 'https://github.com/seek4science/workflow-test-fixture.git',
        }
      }
    }

    wizard = GitWorkflowWizard.new(params: params[:workflow])
    assert_difference('Git::Repository.count', 1) do
      assert_difference('Task.count', 1) do
        assert_enqueued_jobs(1, only: RemoteGitFetchJob) do
          workflow = wizard.run
        end
      end
    end

    assert_equal :select_ref, wizard.next_step
  end

  test 'do not create duplicate repo for same remote' do
    Factory(:remote_repository)
    repo = Git::Repository.find_by_remote('https://github.com/seek4science/workflow-test-fixture.git')
    refute_nil repo

    params = {
      workflow: {
        git_version_attributes: {
          remote: 'https://github.com/seek4science/workflow-test-fixture.git',
        }
      }
    }

    wizard = GitWorkflowWizard.new(params: params[:workflow])
    assert_no_difference('Git::Repository.count') do
      assert_difference('Task.count', 1) do
        assert_enqueued_jobs(1, only: RemoteGitFetchJob) do
          workflow = wizard.run
          assert_equal repo, workflow.git_version.git_repository
        end
      end
    end

    assert_equal :select_ref, wizard.next_step
  end

  test 'direct to select_ref if ref missing' do
    repo = Factory(:remote_repository)
    params = {
      workflow: {
        git_version_attributes: {
          git_repository_id: repo.id,
        }
      }
    }

    wizard = GitWorkflowWizard.new(params: params[:workflow])
    workflow = wizard.run
    assert_equal :select_ref, wizard.next_step
  end

  test 'direct to select_paths if main workflow path missing and cannot be inferred from ro-crate-metadata' do
    repo = Factory(:remote_repository)
    params = {
      workflow: {
        git_version_attributes: {
          git_repository_id: repo.id,
          ref: 'refs/heads/master',
          commit: 'b6312caabe582d156dd351fab98ce78356c4b74c',
        }
      }
    }

    wizard = GitWorkflowWizard.new(params: params[:workflow])
    workflow = wizard.run
    assert_equal :select_paths, wizard.next_step
  end

  test 'skip select_paths if main workflow path can be inferred from ro-crate-metadata.json' do
    repo = Factory(:workflow_ro_crate_repository)
    params = {
      workflow: {
        git_version_attributes: {
          git_repository_id: repo.id,
          ref: 'refs/heads/master',
          commit: 'a321b6e',
        }
      }
    }

    wizard = GitWorkflowWizard.new(params: params[:workflow])
    workflow = wizard.run
    assert_equal 'sort-and-change-case.ga', workflow.git_version.main_workflow_path
    assert_equal :provide_metadata, wizard.next_step
  end

  test 'direct to provide_metadata if repo, ref and main workflow path are present' do
    repo = Factory(:remote_repository)
    params = {
      workflow: {
        git_version_attributes: {
          git_repository_id: repo.id,
          ref: 'refs/heads/master',
          commit: 'b6312caabe582d156dd351fab98ce78356c4b74c',
          main_workflow_path: 'concat_two_files.ga'
        }
      }
    }

    wizard = GitWorkflowWizard.new(params: params[:workflow])
    workflow = wizard.run
    assert_equal :provide_metadata, wizard.next_step
  end

  test 'add error if no remote URL given' do
    params = {
      workflow: {
        git_version_attributes: {
          remote: '',
        }
      }
    }

    wizard = GitWorkflowWizard.new(params: params[:workflow])
    workflow = wizard.run
    assert workflow.errors.added?(:base, 'Git URL was blank.')
    assert_equal :new, wizard.next_step
  end

  test 'copies git annotations when creating new workflow version' do
    workflow = Factory(:ro_crate_git_workflow)
    params = {
      workflow: {
        git_version_attributes: {
          git_repository_id: workflow.git_version.git_repository_id,
          ref: 'refs/heads/master',
          commit: '20eabdc95c69df04d9a43f0a345c4b8349c6a4ff'
        }
      }
    }

    wizard = GitWorkflowWizard.new(params: params[:workflow], workflow: workflow)
    workflow = wizard.run
    assert_equal 'sort-and-change-case.ga', workflow.git_version.main_workflow_path
    assert_equal :provide_metadata, wizard.next_step
  end

  test 'does not copy git annotations when creating new workflow version if path no longer exists' do
    workflow = Factory(:local_git_workflow)
    params = {
      workflow: {
        git_version_attributes: {
          git_repository_id: workflow.git_version.git_repository_id,
          ref: 'refs/heads/master',
          commit: 'ef558beaf17d76b99e0071f9eb0afd38567306b8' # Main workflow was deleted in this commit
        }
      }
    }

    wizard = GitWorkflowWizard.new(params: params[:workflow], workflow: workflow)
    workflow = wizard.run
    assert_nil workflow.git_version.main_workflow_path
    assert_equal :select_paths, wizard.next_step
  end
end
