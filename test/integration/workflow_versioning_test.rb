require 'test_helper'

class WorkflowVersioningTest < ActionDispatch::IntegrationTest
  include MockHelper
  include HtmlHelper

  setup do
    WorkflowClass.find_by_key('Galaxy') || Factory(:galaxy_workflow_class)
  end

  test 'uploads a new version of a workflow' do
    workflow = Factory(:workflow)
    workflow_id = workflow.id
    person = workflow.contributor
    login_as(person.user)

    get new_version_workflow_path(workflow.id)

    assert_response :success

    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'http://workflow.com/rp2.cwl'

    params = { ro_crate: { workflow: { data: fixture_file_upload('files/workflows/1-PreProcessing.ga', 'text/plain') },
                           diagram: { data_url: 'http://somewhere.com/piccy.png' },
                           abstract_cwl: { data_url: 'http://workflow.com/rp2.cwl' } },
               revision_comments: 'A new version!',
               workflow_id: workflow.id
    }

    assert_difference('ContentBlob.count', 1) do
      post create_ro_crate_workflows_path, params: params

      assert_response :success
    end

    assert_equal workflow.id, session[:workflow_id].to_i
    assert_equal 'A new version!', session[:revision_comments]
    workflow = assigns(:workflow)
    assert session[:uploaded_content_blob_id].present?
    assert_equal workflow.content_blob.id, session[:uploaded_content_blob_id]

    post metadata_extraction_ajax_workflows_path(format: :js), params: { workflow_class_id: workflow.workflow_class_id,
                                                                         content_blob_id: workflow.content_blob.id }
    assert_response :success
    assert session[:metadata][:internals].present?

    get provide_metadata_workflows_path

    assert_response :success
    assert_select 'form[action=?]', create_version_metadata_workflow_path(workflow_id)
    assert_select '#workflow_submit_btn[value=?]', 'Update'

    assert_difference('Workflow::Version.count', 1) do
      assert_no_difference('Workflow.count', ) do
        assert_no_difference('ContentBlob.count', ) do
          post create_version_metadata_workflow_path(workflow_id),
               params: session[:metadata].merge(title: 'Something something',
                                                content_blob_id: session[:uploaded_content_blob_id])

          assert_redirected_to workflow_path(workflow_id)

          assert_equal 'A new version!', assigns(:workflow).versions.last.revision_comments
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
