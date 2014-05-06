require 'test_helper'

class WorkflowsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper

  def setup
    @member = Factory :user
    @project = @member.person.projects.first
    login_as @member
  end

  test "extracts metadata on create" do
    assert_difference("Workflow.count") do
      wf_param = {:title => "A workflow", :data=>fixture_file_upload('files/hello_anyone_3_inputs.t2flow'), :project_ids=>[@project.id]}
      post :create, :workflow => wf_param, :sharing=>valid_sharing
    end

    puts assigns(:workflow).errors.full_messages

    assert_equal 3, assigns(:workflow).input_ports.size
    assert_equal 'Hello Anyone With 3 Inputs', assigns(:workflow).title
  end

end
