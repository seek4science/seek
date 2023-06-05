require 'test_helper'

class GitAnnotationTest < ActiveSupport::TestCase
  setup do
    @galaxy_class = WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class)
  end

  test 'get and set git annotation' do
    workflow = FactoryBot.create(:annotationless_local_git_workflow)
    wgv = workflow.git_version

    assert wgv.is_a?(Workflow::Git::Version)

    assert_nil workflow.main_workflow_path

    assert_difference('Git::Annotation.count', 1) do
      disable_authorization_checks { workflow.update!(workflow_class_id: @galaxy_class.id) }
      wgv.reload
      wgv.main_workflow_path = 'concat_two_files.ga'
      disable_authorization_checks { assert wgv.save }
    end

    assert_equal 'concat_two_files.ga', workflow.reload.main_workflow_path

    assert_no_difference('Git::Annotation.count') do
      wgv.main_workflow_path = 'Concat_two_files.cwl'
      wgv.workflow_class_id = (WorkflowClass.find_by_key('cwl') || FactoryBot.create(:cwl_workflow_class)).id
      disable_authorization_checks { assert wgv.save }
    end

    assert_equal 'Concat_two_files.cwl', workflow.reload.main_workflow_path
    assert_equal 687, workflow.main_workflow_blob.size
    assert_equal '0b311dd91d0e485d73d88f8d1c750c7344a16785', workflow.main_workflow_blob.oid
  end

  test 'cannot set git annotation to non-existent path' do
    workflow = FactoryBot.create(:git_version).resource
    wgv = workflow.git_version

    assert wgv.is_a?(Workflow::Git::Version)

    assert_nil workflow.main_workflow_path

    assert_no_difference('Git::Annotation.count') do
      wgv.main_workflow_path = 'banana.ga'
      refute wgv.save
    end

    assert_nil workflow.reload.main_workflow_path
  end

  test 'destroy annotation' do
    workflow = FactoryBot.create(:git_version).resource
    wgv = workflow.git_version

    assert wgv.is_a?(Workflow::Git::Version)

    assert_nil workflow.main_workflow_path

    assert_difference('Git::Annotation.count', 1) do
      disable_authorization_checks { workflow.update!(workflow_class_id: @galaxy_class.id) }
      wgv.reload
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
    end

    assert_difference('Git::Annotation.count', -1) do
      wgv.main_workflow_path = ''
      assert wgv.save
    end

    assert_nil workflow.reload.main_workflow_path
  end

  test 'annotations are removed if file is deleted' do
    workflow = FactoryBot.create(:git_version).resource
    wgv = workflow.git_version
    assert_difference('Git::Annotation.count', 1) do
      disable_authorization_checks { workflow.update!(workflow_class_id: @galaxy_class.id) }
      wgv.reload
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
    end

    assert_difference('Git::Annotation.count', -1) do
      wgv.remove_file('concat_two_files.ga')
      refute wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
    end
  end

  test 'annotations are deleted if git version is deleted' do
    workflow = FactoryBot.create(:git_version).resource
    wgv = workflow.git_version
    assert_difference('Git::Annotation.count', 1) do
      disable_authorization_checks { workflow.update!(workflow_class_id: @galaxy_class.id) }
      wgv.reload
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
    end

    assert_difference('Git::Annotation.count', -1) do
      disable_authorization_checks { wgv.destroy }
    end
  end

  test 'annotations are not removed if option set' do
    workflow = FactoryBot.create(:git_version).resource
    wgv = workflow.git_version
    assert_difference('Git::Annotation.count', 1) do
      disable_authorization_checks { workflow.update!(workflow_class_id: @galaxy_class.id) }
      wgv.reload
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
    end

    assert_no_difference('Git::Annotation.count', -1) do
      wgv.remove_file('concat_two_files.ga', update_annotations: false)
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
    end
  end

  test 'annotations are moved if file is renamed' do
    workflow = FactoryBot.create(:git_version).resource
    wgv = workflow.git_version
    assert_difference('Git::Annotation.count', 1) do
      disable_authorization_checks { workflow.update!(workflow_class_id: @galaxy_class.id) }
      wgv.reload
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
      refute wgv.git_annotations.where(path: 'concat_2_files.ga', key: 'main_workflow').exists?
    end

    assert_no_difference('Git::Annotation.count') do
      wgv.move_file('concat_two_files.ga', 'concat_2_files.ga')
      refute wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
      assert wgv.git_annotations.where(path: 'concat_2_files.ga', key: 'main_workflow').exists?
    end
  end

  test 'annotations are not moved if option set' do
    workflow = FactoryBot.create(:git_version).resource
    wgv = workflow.git_version
    assert_difference('Git::Annotation.count', 1) do
      disable_authorization_checks { workflow.update!(workflow_class_id: @galaxy_class.id) }
      wgv.reload
      wgv.main_workflow_path = 'concat_two_files.ga'
      assert wgv.save
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
      refute wgv.git_annotations.where(path: 'concat_2_files.ga', key: 'main_workflow').exists?
    end

    assert_no_difference('Git::Annotation.count') do
      wgv.move_file('concat_two_files.ga', 'concat_2_files.ga', update_annotations: false)
      assert wgv.git_annotations.where(path: 'concat_two_files.ga', key: 'main_workflow').exists?
      refute wgv.git_annotations.where(path: 'concat_2_files.ga', key: 'main_workflow').exists?
    end
  end

  test 'get and set remote source annotations' do
    workflow = FactoryBot.create(:annotationless_local_git_workflow)
    wgv = workflow.git_version

    assert wgv.is_a?(Workflow::Git::Version)

    assert_nil workflow.main_workflow_path

    assert_difference('Git::Annotation.count', 2) do
      disable_authorization_checks { workflow.update!(workflow_class_id: @galaxy_class.id) }
      wgv.reload
      wgv.main_workflow_path = 'concat_two_files.ga'
      wgv.remote_sources = { 'concat_two_files.ga' => 'https://workflows.example.com/concat_two_files.ga' }
      disable_authorization_checks { assert wgv.save }
    end

    assert_equal 'concat_two_files.ga', workflow.reload.main_workflow_path

    assert_equal({ 'concat_two_files.ga' => 'https://workflows.example.com/concat_two_files.ga' }, wgv.reload.remote_sources)

    assert_no_difference('Git::Annotation.count') do
      wgv.main_workflow_path = 'Concat_two_files.cwl'
      wgv.workflow_class_id = (WorkflowClass.find_by_key('cwl') || FactoryBot.create(:cwl_workflow_class)).id
      wgv.remote_sources = { 'Concat_two_files.cwl' => 'https://workflows.example.com/concat_two_files.cwl' }
      disable_authorization_checks { assert wgv.save }
    end

    assert_equal 'Concat_two_files.cwl', workflow.reload.main_workflow_path
    assert_equal({ 'Concat_two_files.cwl' => 'https://workflows.example.com/concat_two_files.cwl' }, wgv.reload.remote_sources)

    assert_difference('Git::Annotation.count', -1) do
      wgv.remote_sources = []
      disable_authorization_checks { assert wgv.save }
    end

    assert_equal({}, wgv.reload.remote_sources)
  end
end
