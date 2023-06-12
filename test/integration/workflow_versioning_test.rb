require 'test_helper'

class WorkflowVersioningTest < ActionDispatch::IntegrationTest
  include MockHelper
  include HtmlHelper

  setup do
    @galaxy = WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class)
  end

  test 'uploads a new version of a workflow' do
    workflow = FactoryBot.create(:workflow)
    workflow_id = workflow.id
    person = workflow.contributor
    login_as(person.user)

    assert_equal 0, workflow.inputs.count
    assert_equal 0, workflow.versions.first.inputs.count

    get new_version_workflow_path(workflow.id)

    assert_response :success

    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'http://workflow.com/rp2.cwl'

    params = { ro_crate: { workflow: { data: fixture_file_upload('workflows/1-PreProcessing.ga', 'text/plain') },
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
      assert_no_difference('Workflow.count') do
        assert_no_difference('ContentBlob.count') do
          post create_version_metadata_workflow_path(workflow_id),
               params: { workflow: metadata,
                         revision_comments: params[:revision_comments],
                         content_blob_uuid: assigns(:content_blob).uuid }

          assert_redirected_to workflow_path(workflow_id)

          assert_equal 'A new version!', assigns(:workflow).versions.last.revision_comments
          assert_equal 'Something something', assigns(:workflow).title
          assert_equal 5, assigns(:workflow).inputs.count
          assert_equal 5, assigns(:workflow).versions.last.inputs.count
          assert_equal 0, assigns(:workflow).versions.first.inputs.count
        end
      end
    end
  end

  test 'new workflow version upload copes with errors' do
    workflow = FactoryBot.create(:workflow)
    projects = workflow.projects
    workflow_id = workflow.id
    person = workflow.contributor
    login_as(person.user)

    assert_equal 0, workflow.inputs.count
    assert_equal 0, workflow.versions.first.inputs.count
    assert_equal 732, workflow.find_version(1).content_blob.file_size

    get new_version_workflow_path(workflow.id)

    assert_response :success

    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'http://workflow.com/rp2.cwl'

    params = { ro_crate: { workflow: { data: fixture_file_upload('workflows/1-PreProcessing.ga', 'text/plain') },
                           diagram: { data_url: 'http://somewhere.com/piccy.png' },
                           abstract_cwl: { data_url: 'http://workflow.com/rp2.cwl' } },
               revision_comments: 'A new version!',
               workflow_class_id: @galaxy.id,
               workflow_id: workflow.id
    }

    assert_difference('ContentBlob.count', 1) do
      post create_ro_crate_workflows_path, params: params
    end

    cb = assigns(:content_blob)

    metadata = assigns(:metadata).merge(title: 'Something something')
    metadata[:internals] = metadata[:internals].to_json

    assert_response :success
    assert_select 'form[action=?]', create_version_metadata_workflow_path(workflow_id)
    assert_select '#workflow_submit_btn[value=?]', 'Update'

    assert_no_difference('Workflow::Version.count', 1) do
      assert_no_difference('Workflow.count') do
        assert_no_difference('ContentBlob.count') do
          post create_version_metadata_workflow_path(workflow_id),
               params: { workflow: metadata.merge(project_ids: ['']), # Cause an error
                         revision_comments: params[:revision_comments],
                         content_blob_uuid: assigns(:content_blob).uuid }

          assert_response :unprocessable_entity

          assert_nil cb.reload.asset
          refute_equal 'A new version!', assigns(:workflow).versions.last.revision_comments
          refute_equal 'Something something', assigns(:workflow).versions.last.title
        end
      end
    end

    # Retry with no errors
    assert_difference('Workflow::Version.count', 1) do
      assert_no_difference('Workflow.count') do
        assert_no_difference('ContentBlob.count') do
          post create_version_metadata_workflow_path(workflow_id),
               params: { workflow: metadata.merge(project_ids: projects.map { |p| p.id.to_s }),
                         revision_comments: params[:revision_comments],
                         content_blob_uuid: assigns(:content_blob).uuid }

          assert_redirected_to workflow_path(workflow_id)

          assert_equal 'A new version!', assigns(:workflow).versions.last.revision_comments
          assert_equal 'Something something', assigns(:workflow).title
          assert_equal 5, assigns(:workflow).inputs.count
          assert_equal 5, assigns(:workflow).versions.last.inputs.count
          assert_equal 0, assigns(:workflow).versions.first.inputs.count
        end
      end
    end

    assert_equal 2, workflow.reload.versions.count
    assert_equal 732, workflow.find_version(1).content_blob.file_size
    assert_equal 12349, workflow.find_version(2).content_blob.file_size
  end

  test 'new workflow version upload copes with workflow class change' do
    workflow = FactoryBot.create(:workflow)
    projects = workflow.projects
    workflow_id = workflow.id
    person = workflow.contributor
    login_as(person.user)

    assert_equal 'cwl', workflow.find_version(1).workflow_class.key

    get new_version_workflow_path(workflow.id)

    assert_response :success

    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'http://workflow.com/rp2.cwl'

    params = { ro_crate: { workflow: { data: fixture_file_upload('workflows/1-PreProcessing.ga', 'text/plain') } },
               revision_comments: 'A galaxy version!',
               workflow_class_id: @galaxy.id,
               workflow_id: workflow.id
    }

    assert_difference('ContentBlob.count', 1) do
      post create_ro_crate_workflows_path, params: params
    end

    cb = assigns(:content_blob)

    metadata = assigns(:metadata).merge(title: 'Something something')
    metadata[:internals] = metadata[:internals].to_json

    assert_response :success
    assert_empty assigns(:workflow).extraction_errors
    assert_equal 'galaxy', assigns(:workflow).workflow_class.key
    assert_select 'form[action=?]', create_version_metadata_workflow_path(workflow_id)
    assert_select '#workflow_submit_btn[value=?]', 'Update'

    assert_difference('Workflow::Version.count', 1) do
      assert_no_difference('Workflow.count') do
        assert_no_difference('ContentBlob.count') do
          post create_version_metadata_workflow_path(workflow_id),
               params: { workflow: metadata.merge(project_ids: projects.map { |p| p.id.to_s }),
                         revision_comments: params[:revision_comments],
                         content_blob_uuid: assigns(:content_blob).uuid }

          assert_redirected_to workflow_path(workflow_id)

          assert_equal 'A galaxy version!', assigns(:workflow).versions.last.revision_comments
          assert_equal 'Something something', assigns(:workflow).title
          assert_equal 'galaxy', assigns(:workflow).versions.last.workflow_class.key
        end
      end
    end

    assert_equal 'galaxy', workflow.find_version(2).workflow_class.key
  end

  private

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end
