require 'test_helper'

class WorkflowsControllerTest < ActionController::TestCase
  fixtures :workflow_input_port_types, :workflow_output_port_types, :workflow_categories

  include AuthenticatedTestHelper
  include SharingFormTestHelper

  def setup
    @member = Factory :user
    @project = @member.person.projects.first
    login_as @member
  end

  test 'show' do
    workflow = Factory :workflow, contributor: @member
    get :show, id: workflow.id
    assert_response :success
    assert_select 'h1', text: /#{workflow.title}/
  end

  test 'edit' do
    workflow = Factory :workflow, contributor: @member
    get :edit, id: workflow.id
    assert_response :success
    assert_select 'h1', text: /#{workflow.title}/
  end

  test 'extracts metadata on create' do
    wf_param = { title: 'A workflow', project_ids: [@project.id] }
    cblob_param = { data: ActionDispatch::Http::UploadedFile.new(filename: 'hello_anyone_3_inputs.t2flow',
                                                                 content_type: nil,
                                                                 tempfile: fixture_file_upload('files/hello_anyone_3_inputs.t2flow'))
    }
    assert_difference('Workflow.count') do
      post :create, workflow: wf_param, content_blobs: [cblob_param], sharing: valid_sharing
    end

    assert_equal 3, assigns(:workflow).input_ports.size
    assert_equal 'Hello Anyone With 3 Inputs', assigns(:workflow).title
  end

  test 'public visibility' do
    workflow = Factory :workflow, contributor: @member, policy: Factory(:public_policy)
    get :show, id: workflow.id
    assert_response :success
    assert_select 'span[class="visibility public"]', text: /Public/

    policy = workflow.policy
    policy.access_type = Policy::NO_ACCESS
    policy.save
    workflow.reload

    get :show, id: workflow.id
    assert_response :success
    assert_select 'span[class="visibility public"]', text: /Public/, count: 0
  end
end
