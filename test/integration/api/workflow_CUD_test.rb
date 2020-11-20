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
                   'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'workflows', 'rp2-to-rp2path.cwl')) }

    assert_response :success
    blob = wf.content_blob.reload
    refute_equal original_md5, blob.reload.md5sum
    refute blob.no_content?
    assert blob.file_size > 0
  end

  test 'can create workflow with remote content' do
    stub_request(:get, 'http://mockedlocation.com/workflow.cwl').to_return(body: File.new("#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path.cwl"),
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
end
