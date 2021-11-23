require 'test_helper'
require 'integration/api_test_helper'

class WorkflowCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'workflow'
    Factory(:cwl_workflow_class) # Make sure the CWL class is present
    @plural_clz = @clz.pluralize
    @project = @current_user.person.projects.first
    investigation = Factory(:investigation, projects: [@project], contributor: @current_person)
    study = Factory(:study, investigation: investigation, contributor: @current_person)
    @assay = Factory(:assay, study: study, contributor: @current_person)
    @creator = Factory(:person)
    @publication = Factory(:publication, projects: [@project])

    template_file = File.join(ApiTestHelper.template_dir, 'post_max_workflow.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    workflow = Factory(:workflow, policy: Factory(:public_policy), contributor: @current_person, creators: [@creator])
    @to_patch = load_template("patch_min_#{@clz}.json.erb", { id: workflow.id })
  end

  test 'can add content to API-created workflow' do
    wf = Factory(:api_cwl_workflow, contributor: @current_person)

    assert wf.content_blob.no_content?
    assert wf.can_download?(@current_user)
    assert wf.can_edit?(@current_user)

    original_md5 = wf.content_blob.md5sum
    put workflow_content_blob_path(wf, wf.content_blob),
        headers: { 'Accept' => 'application/json',
                   'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'workflows', 'rp2', 'workflows', 'rp2-to-rp2path.cwl')) }

    assert_response :success
    blob = wf.content_blob.reload
    refute_equal original_md5, blob.reload.md5sum
    refute blob.no_content?
    assert blob.file_size > 0
  end

  test 'can create workflow with remote content' do
    stub_request(:get, 'http://mockedlocation.com/workflow.cwl').to_return(body: File.new("#{Rails.root}/test/fixtures/files/workflows/rp2/workflows/rp2-to-rp2path.cwl"),
                                                                           status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })
    stub_request(:head, 'http://mockedlocation.com/workflow.cwl').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })

    template_file = File.join(ApiTestHelper.template_dir, 'post_remote_workflow.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))
    validate_json_against_fragment @to_post.to_json, "#/definitions/#{@clz.camelize(:lower)}Post"

    assert_difference("#{@clz.classify}.count") do
      post "/#{@plural_clz}.json", params: @to_post
      assert_response :success
    end

    validate_json_against_fragment response.body, "#/definitions/#{@clz.camelize(:lower)}Response"

    h = JSON.parse(response.body)

    hash_comparison(@to_post['data']['attributes'], h['data']['attributes'])
    hash_comparison(populate_extra_attributes(@to_post), h['data']['attributes'])

    hash_comparison(@to_post['data']['relationships'], h['data']['relationships'])
    hash_comparison(populate_extra_relationships(@to_post), h['data']['relationships'])
  end

  test 'can post RO crate' do
    Factory(:nextflow_workflow_class)

    assert_difference('Workflow.count', 1) do
      post workflows_path, params: {
          ro_crate: fixture_file_upload('files/workflows/ro-crate-nf-core-ampliseq.crate.zip'),
          workflow: {
              project_ids: [@project.id]
          }
      }

      assert_response :success
      assert_equal 'Nextflow', assigns(:workflow).workflow_class.title
      assert_equal 'nf-core/ampliseq', assigns(:workflow).title
      assert assigns(:workflow).git_version.total_size > 100
      assert_equal 'main.nf', assigns(:workflow).ro_crate.main_workflow.id
    end
  end

  test 'can post RO crate as new version' do
    Factory(:nextflow_workflow_class)
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy), contributor: @current_person)

    assert_no_difference('Workflow.count') do
      assert_difference('Git::Version.count', 1) do
        post create_version_workflow_path(workflow.id), params: {
            ro_crate: fixture_file_upload('files/workflows/ro-crate-nf-core-ampliseq.crate.zip'),
            workflow: {
                project_ids: [@project.id]
            },
            revision_comments: 'new ver'
        }

        assert_response :success
        assert_equal 2, assigns(:workflow).reload.version
        assert_equal 'Nextflow', assigns(:workflow).workflow_class.title
        assert_equal 'nf-core/ampliseq', assigns(:workflow).title
        assert assigns(:workflow).git_version.total_size > 100
        assert_equal 'main.nf', assigns(:workflow).ro_crate.main_workflow.id
      end
    end
  end

  test 'cannot post RO crate as new version to remote git workflows' do
    Factory(:nextflow_workflow_class)
    workflow = Factory(:remote_git_workflow, policy: Factory(:public_policy), contributor: @current_person)

    assert_no_difference('Workflow.count') do
      assert_no_difference('Git::Version.count') do
        post create_version_workflow_path(workflow.id), params: {
            ro_crate: fixture_file_upload('files/workflows/ro-crate-nf-core-ampliseq.crate.zip'),
            workflow: {
                project_ids: [@project.id]
            },
            revision_comments: 'new ver'
        }

        assert_response :unprocessable_entity
        assert @response.body.include?('Cannot add RO-Crate to remote workflows')
      end
    end
  end

  test 'cannot post RO crate with missing metadata' do
    assert_no_difference('Workflow.count') do
      post workflows_path, params: {
          ro_crate: fixture_file_upload('files/workflows/workflow-4-1.crate.zip'),
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
          ro_crate: fixture_file_upload('files/workflows/workflow-4-1.crate.zip'),
          workflow: {
              title: 'Alternative title',
              project_ids: [@project.id]
          }
      }

      assert_response :success
      assert_equal 'Alternative title', assigns(:workflow).title
    end
  end
end
