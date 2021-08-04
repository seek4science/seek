require 'test_helper'

class GitAnnotationTest < ActiveSupport::TestCase

  test 'get and set git annotation' do
    workflow = Factory(:annotationless_local_git_workflow)
    wgv = workflow.git_version

    assert wgv.is_a?(Workflow::GitVersion)

    assert_nil workflow.main_workflow_path

    assert_difference('GitAnnotation.count', 1) do
      wgv.main_workflow_path = 'concat_two_files.ga'
      disable_authorization_checks { assert wgv.save }
    end

    assert_equal 'concat_two_files.ga', workflow.reload.main_workflow_path

    assert_no_difference('GitAnnotation.count') do
      wgv.main_workflow_path = 'Concat_two_files.cwl'
      wgv.workflow_class_id = (WorkflowClass.find_by_key('cwl') || Factory(:cwl_workflow_class)).id
      disable_authorization_checks { assert wgv.save }
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

  test 'destroy annotation' do
    workflow = Factory(:git_version).resource
    wgv = workflow.git_version

    assert wgv.is_a?(Workflow::GitVersion)

    assert_nil workflow.main_workflow_path

    assert_difference('GitAnnotation.count', 1) do
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
    end

    assert_difference('GitAnnotation.count', -1) do
      wgv.main_workflow_path = ''
      assert wgv.save
    end

    assert_nil workflow.reload.main_workflow_path
  end

  test 'annotations are removed if file is deleted' do
    workflow = Factory(:git_version).resource
    wgv = workflow.git_version
    assert_difference('GitAnnotation.count', 1) do
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
    end

    assert_difference('GitAnnotation.count', -1) do
      wgv.remove_file('concat_two_files.ga')
      refute wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
    end
  end

  test 'annotations are not removed if option set' do
    workflow = Factory(:git_version).resource
    wgv = workflow.git_version
    assert_difference('GitAnnotation.count', 1) do
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
    end

    assert_no_difference('GitAnnotation.count', -1) do
      wgv.remove_file('concat_two_files.ga', update_annotations: false)
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
    end
  end

  test 'annotations are moved if file is renamed' do
    workflow = Factory(:git_version).resource
    wgv = workflow.git_version
    assert_difference('GitAnnotation.count', 1) do
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
      refute wgv.git_annotations.where(path: 'concat_2_files.ga', key: 'main_workflow').exists?
    end

    assert_no_difference('GitAnnotation.count') do
      wgv.move_file('concat_two_files.ga', 'concat_2_files.ga')
      refute wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
      assert wgv.git_annotations.where(path: 'concat_2_files.ga', key: 'main_workflow').exists?
    end
  end

  test 'annotations are not moved if option set' do
    workflow = Factory(:git_version).resource
    wgv = workflow.git_version
    assert_difference('GitAnnotation.count', 1) do
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
      refute wgv.git_annotations.where(path: 'concat_2_files.ga', key: 'main_workflow').exists?
    end

    assert_no_difference('GitAnnotation.count') do
      wgv.move_file('concat_two_files.ga', 'concat_2_files.ga', update_annotations: false)
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
      refute wgv.git_annotations.where(path: 'concat_2_files.ga', key: 'main_workflow').exists?
    end
  end
end
