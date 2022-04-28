require 'test_helper'

class WorkflowApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    Factory(:cwl_workflow_class) # Make sure the CWL class is present
    @project = @current_user.person.projects.first
    investigation = Factory(:investigation, projects: [@project], contributor: current_person)
    study = Factory(:study, investigation: investigation, contributor: current_person)
    Factory(:edam_topics_controlled_vocab)
    Factory(:edam_operations_controlled_vocab)
    @assay = Factory(:assay, study: study, contributor: current_person)
    @creator = Factory(:person)
    @publication = Factory(:publication, projects: [@project])
    @workflow = Factory(:workflow, policy: Factory(:public_policy), contributor: current_person, creators: [@creator])
  end

  test 'can add content to API-created workflow' do
    wf = Factory(:api_cwl_workflow, contributor: current_person)

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

    template = load_template('post_remote_workflow.json.erb')
    api_post_test(template)
  end
end
