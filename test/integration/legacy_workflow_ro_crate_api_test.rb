require 'test_helper'

class LegacyWorkflowRoCrateApiTest < ActionDispatch::IntegrationTest
  setup do
    admin = FactoryBot.create(:admin)
    login_as(admin.user)
    FactoryBot.create(:cwl_workflow_class) # Make sure the CWL class is present
    FactoryBot.create(:nextflow_workflow_class)
    @project = admin.person.projects.first
    @git_support = Seek::Config.git_support_enabled
    Seek::Config.git_support_enabled = false
  end

  teardown do
    Seek::Config.git_support_enabled = @git_support
  end

  test 'can post RO crate' do
    assert_difference('Workflow.count', 1) do
      post workflows_path, params: {
        ro_crate: fixture_file_upload('workflows/ro-crate-nf-core-ampliseq.crate.zip'),
        workflow: {
          project_ids: [@project.id]
        }
      }

      assert_response :success
      assert_equal 'Nextflow', assigns(:workflow).workflow_class.title
      assert_equal 'nf-core/ampliseq', assigns(:workflow).title
      assert assigns(:workflow).content_blob.file_size > 100
      assert_equal 'main.nf', assigns(:workflow).ro_crate.main_workflow.id
    end
  end

  test 'can post RO crate as new version' do
    workflow = FactoryBot.create(:workflow, policy: FactoryBot.create(:public_policy), contributor: @current_person)

    assert_no_difference('Workflow.count') do
      assert_difference('Workflow::Version.count', 1) do
        post create_version_workflow_path(workflow.id), params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-nf-core-ampliseq.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          },
          revision_comments: 'new ver'
        }

        assert_response :success
        assert_equal 2, assigns(:workflow).reload.version
        assert_equal 'Nextflow', assigns(:workflow).workflow_class.title
        assert_equal 'nf-core/ampliseq', assigns(:workflow).title
        assert assigns(:workflow).content_blob.file_size > 100
        assert_equal 'main.nf', assigns(:workflow).ro_crate.main_workflow.id
      end
    end
  end

  test 'cannot post RO crate with missing metadata' do
    assert_no_difference('Workflow.count') do
      post workflows_path, params: {
        ro_crate: fixture_file_upload('workflows/workflow-4-1.crate.zip'),
        workflow: {
          project_ids: [@project.id]
        }
      }

      assert_response :unprocessable_entity
      assert @response.body.include?("can't be blank")
    end
  end

  test 'can supplement metadata when posting RO crate' do
    assert_difference('Workflow.count', 1) do
      post workflows_path, params: {
        ro_crate: fixture_file_upload('workflows/workflow-4-1.crate.zip'),
        workflow: {
          title: 'Alternative title',
          project_ids: [@project.id]
        }
      }

      assert_response :success
      assert_equal 'Alternative title', assigns(:workflow).title
    end
  end

  private

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end