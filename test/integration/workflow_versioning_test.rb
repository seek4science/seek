require 'test_helper'

class WorkflowVersioningTest < ActionDispatch::IntegrationTest
  include MockHelper
  include HtmlHelper

  setup do
    @galaxy = WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class)
  end

  test 'uploads a new version of a workflow' do
    workflow = Factory(:workflow)
    workflow_id = workflow.id
    person = workflow.contributor
    login_as(person.user)

    assert_equal 0, workflow.inputs.count
    assert_equal 0, workflow.versions.first.inputs.count

    get new_version_workflow_path(workflow.id)

    assert_response :success

    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'http://workflow.com/rp2.cwl'

    params = { ro_crate: { workflow: { data: fixture_file_upload('files/workflows/1-PreProcessing.ga', 'text/plain') },
                           diagram: { data_url: 'http://somewhere.com/piccy.png' },
                           abstract_cwl: { data_url: 'http://workflow.com/rp2.cwl' } },
               revision_comments: 'A new version!',
               workflow_class_id: @galaxy.id,
               workflow_id: workflow.id
    }

    assert_difference('ContentBlob.count', 1) do
      post create_ro_crate_workflows_path, params: params
    end

    metadata = assigns(:metadata).merge(title: 'Something something')
    metadata[:internals] = metadata[:internals].to_json

    assert_response :success
    assert_select 'form[action=?]', create_version_metadata_workflow_path(workflow_id)
    assert_select '#workflow_submit_btn[value=?]', 'Update'

    assert_difference('Workflow::Version.count', 1) do
      assert_no_difference('Workflow.count', ) do
        assert_no_difference('ContentBlob.count', ) do
          post create_version_metadata_workflow_path(workflow_id),
               params: { workflow: metadata,
                         revision_comments: params[:revision_comments],
                         content_blob_uuid: workflow.content_blob.uuid }

          assert_redirected_to workflow_path(workflow_id)

          assert_equal 'A new version!', assigns(:workflow).versions.last.revision_comments
          assert_equal 'Something something', assigns(:workflow).title
          assert_equal 12, assigns(:workflow).inputs.count
          assert_equal 12, assigns(:workflow).versions.last.inputs.count
          assert_equal 0, assigns(:workflow).versions.first.inputs.count
        end
      end
    end
  end

  private

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end
