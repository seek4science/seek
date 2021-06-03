require 'test_helper'

class GitAnnotationTest < ActiveSupport::TestCase

  test 'get and set git annotation' do
    workflow = Factory(:git_version).resource
    wgv = workflow.git_version

    assert wgv.is_a?(Workflow::GitVersion)

    assert_nil workflow.main_workflow_path

    assert_difference('GitAnnotation.count', 1) do
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
    end

    assert_equal 'concat_two_files.ga', workflow.reload.main_workflow_path

    assert_no_difference('GitAnnotation.count') do
      wgv.main_workflow_path = 'Concat_two_files.cwl'
      assert wgv.save
    end

    assert_equal 'Concat_two_files.cwl', workflow.reload.main_workflow_path
  end

  test 'cannot set git annotation to non-existent path' do
    workflow = Factory(:git_version).resource
    wgv = workflow.git_version

    assert wgv.is_a?(Workflow::GitVersion)

    assert_nil workflow.main_workflow_path

    assert_no_difference('GitAnnotation.count') do
      wgv.main_workflow_path = 'banana.ga'
      refute wgv.save
    end

    assert_nil workflow.reload.main_workflow_path
  end
end
