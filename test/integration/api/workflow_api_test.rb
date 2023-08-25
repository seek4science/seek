require 'test_helper'

class WorkflowApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    FactoryBot.create(:cwl_workflow_class) # Make sure the CWL class is present
    @project = @current_user.person.projects.first
    investigation = FactoryBot.create(:investigation, projects: [@project], contributor: current_person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: current_person)
    FactoryBot.create(:operations_controlled_vocab) unless SampleControlledVocab::SystemVocabs.operations_controlled_vocab
    FactoryBot.create(:topics_controlled_vocab) unless SampleControlledVocab::SystemVocabs.topics_controlled_vocab
    @assay = FactoryBot.create(:assay, study: study, contributor: current_person)
    @creator = FactoryBot.create(:person)
    @publication = FactoryBot.create(:publication, projects: [@project])
    @presentation = FactoryBot.create(:presentation, projects: [@project], contributor: current_person)
    @data_file = FactoryBot.create(:data_file, projects: [@project], contributor: current_person)
    @document = FactoryBot.create(:document, projects: [@project], contributor: current_person)
    @sop = FactoryBot.create(:sop, projects: [@project], contributor: current_person)
    @workflow = FactoryBot.create(:workflow, policy: FactoryBot.create(:public_policy), contributor: current_person, creators: [@creator])
  end

  test 'can add content to API-created workflow' do
    wf = FactoryBot.create(:api_cwl_workflow, contributor: current_person)

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

  test 'can lookup tool names if only id provided' do
    VCR.use_cassette('bio_tools/fetch_galaxy_tool_names') do
      template = load_template('post_tooled_workflow.json.erb')

      post '/workflows.json', params: template, as: :json
      assert_response :success

      validate_json response.body, "#/components/schemas/#{singular_name.camelize(:lower)}Response"
      res = JSON.parse(response.body)
      tools = res['data']['attributes']['tools']
      assert_equal 3, tools.length
      assert_equal('MultiQC', tools.detect { |t| t['id'] == 'https://bio.tools/multiqc' }['name'])
      assert_equal('European Nucleotide Archive (ENA)', tools.detect { |t| t['id'] == 'https://bio.tools/ena' }['name'])
      assert_equal('Ruby!!!', tools.detect { |t| t['id'] == 'https://bio.tools/bioruby' }['name'])
      assert_nil tools.detect { |t| t['id'] == 'https://ignore.me/galaxy' }
    end
  end
end
