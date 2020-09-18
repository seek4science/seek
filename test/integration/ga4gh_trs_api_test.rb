require 'test_helper'

class Ga4ghTrsApiTest < ActionDispatch::IntegrationTest
  include AuthenticatedTestHelper

  fixtures :users, :people

  test 'should not work if disabled' do
    with_config_value(:ga4gh_trs_api_enabled, false) do
      get "/ga4gh/trs/v2/tools"
      assert_response :not_found
    end
  end

  test 'should get service info' do
    get "/ga4gh/trs/v2/service-info"
    assert_response :success
    r = JSON.parse(@response.body)
    assert_equal Seek::Config.application_name, r['name']
    assert_equal "mailto:#{Seek::Config.support_email_address}", r['contactUrl']
    assert_equal "test", r['environment']
  end

  test 'should get tool classes' do
    get "/ga4gh/trs/v2/toolClasses"
    assert_response :success
    r = JSON.parse(@response.body)
    assert_equal 1, r.length
    assert_equal 'Workflow', r.first['name']
  end

  test 'should list workflows as tools' do
    workflow = Factory(:workflow, policy: Factory(:public_policy))

    assert workflow.can_view?
    get "/ga4gh/trs/v2/tools"
    assert_response :success
    ids = JSON.parse(@response.body).map { |t| t['id'] }
    assert ids.include?(workflow.id.to_s)
  end

  test 'should not list private workflows' do
    workflow = Factory(:workflow, policy: Factory(:private_policy))

    refute workflow.can_view?
    get "/ga4gh/trs/v2/tools"
    assert_response :success
    ids = JSON.parse(@response.body).map { |t| t['id'] }
    refute ids.include?(workflow.id.to_s)
  end

  test 'should get workflow as tool' do
    workflow = Factory(:workflow, policy: Factory(:public_policy))

    assert workflow.can_view?
    get "/ga4gh/trs/v2/tools/#{workflow.id}"
    assert_response :success
  end

  test 'should throw not found error in correct format' do
    get "/ga4gh/trs/v2/tools/3489713857"
    r = JSON.parse(@response.body)
    assert_response :not_found
    assert_equal 404, r['code']
    assert r['message'].include?("Couldn't find")
  end

  test 'should throw not found error for private workflow' do
    workflow = Factory(:workflow, policy: Factory(:private_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}"
    r = JSON.parse(@response.body)
    assert_response :not_found
    assert_equal 404, r['code']
    assert r['message'].include?("Couldn't find")
  end

  test 'should list workflow versions as tool versions' do
    workflow = Factory(:workflow, policy: Factory(:public_policy))
    disable_authorization_checks do
      workflow.save_as_new_version
      workflow.save_as_new_version
    end

    assert 3, workflow.reload.versions.count
    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions"
    assert_response :success
    ids = JSON.parse(@response.body).map { |t| t['id'] }
    assert_includes ids, '1'
    assert_includes ids, '2'
    assert_includes ids, '3'
  end

  test 'should get workflow version as tool version' do
    workflow = Factory(:workflow, policy: Factory(:public_policy))

    assert 1, workflow.reload.versions.count
    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1"
    assert_response :success
  end

  test 'should list tool version files for correct descriptor' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/GALAXY/files"
    assert_response :success
    r = JSON.parse(@response.body)
    assert_equal 5, r.length
    galaxy = r.detect { |f| f['path'] == 'Genomics-1-PreProcessing_without_downloading_from_SRA.ga' }
    diagram = r.detect { |f| f['path'] == 'Genomics-1-PreProcessing_without_downloading_from_SRA.svg' }
    assert galaxy
    assert_equal 'PRIMARY_DESCRIPTOR', galaxy['file_type']
    assert diagram
    assert_equal 'OTHER', diagram['file_type']
  end

  test 'should get zip of all files' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/GALAXY/files?format=zip"
    assert_response :success
    assert_equal 'application/zip', @response.headers['Content-Type']

    Dir.mktmpdir do |dir|
      t = Tempfile.new('the.crate.zip')
      t.binmode
      t << response.body
      t.close
      crate = ROCrate::WorkflowCrateReader.read_zip(t.path, target_dir: dir)
      assert crate.main_workflow
    end
  end

  test 'should not list tool version files for wrong descriptor' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/NFL/files"
    assert_response :not_found
  end

  test 'should get main workflow as primary descriptor' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/GALAXY/descriptor"
    assert_response :success
    assert @response.body.include?('a_galaxy_workflow')
  end

  test 'should get descriptor file via relative path' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/GALAXY/descriptor/Genomics-1-PreProcessing_without_downloading_from_SRA.ga"
    assert_response :success
    assert_equal 'application/json; charset=utf-8', @response.headers['Content-Type']
    assert @response.body.include?('a_galaxy_workflow')
  end

  test 'should get nested descriptor file via relative path' do
    workflow = Factory(:nf_core_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/NFL/descriptor/docs/images/nfcore-ampliseq_logo.png", headers: { 'Accept' => 'text/plain' }
    assert_response :success
    assert_equal 'text/plain; charset=utf-8', @response.headers['Content-Type']
    assert @response.body.start_with?("\x89PNG\r\n")
  end

  test 'should get plain descriptor file via relative path' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/PLAIN_GALAXY/descriptor/Genomics-1-PreProcessing_without_downloading_from_SRA.svg"
    assert_response :success
    assert_equal 'text/plain; charset=utf-8', @response.headers['Content-Type']
    assert @response.body.start_with?('<?xml version="1')
  end

  test 'should 404 on missing descriptor file via relative path' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/GALAXY/descriptor/../.."
    assert_response :not_found
  end

  test 'should get containerfile if Dockerfile present' do
    workflow = Factory(:nf_core_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/NFL/files"
    assert_response :success
    r = JSON.parse(@response.body)
    assert_equal 33, r.length
    main_wf = r.detect { |f| f['path'] == 'main.nf' }
    dockerfile = r.detect { |f| f['path'] == 'Dockerfile' }
    config = r.detect { |f| f['path'] == 'nextflow.config' }
    deep_file = r.detect { |f| f['path'] == 'docs/images/nfcore-ampliseq_logo.png' }
    assert main_wf
    assert_equal 'PRIMARY_DESCRIPTOR', main_wf['file_type']
    assert dockerfile
    assert_equal 'CONTAINERFILE', dockerfile['file_type']
    assert config
    assert_equal 'OTHER', config['file_type']
    assert deep_file
    assert_equal 'OTHER', deep_file['file_type']

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/containerfile"
    assert_response :success
    assert_equal 'application/json; charset=utf-8', @response.headers['Content-Type']
    r = JSON.parse(@response.body)
    assert r.first['content'].include?('matplotlib')

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/containerfile", headers: { 'Accept' => 'text/plain' }
    assert_response :success
    assert_equal 'text/plain; charset=utf-8', @response.headers['Content-Type']
    assert @response.body.start_with?('FROM nfcore/base:1.7')
  end

  test 'should 404 if no containerfile' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))
    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/containerfile"
    assert_response :not_found
    r = JSON.parse(@response.body)
    assert r['message'].include?('No container')
  end

  test 'should return empty array if no tests' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))
    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/GALAXY/tests"
    r = JSON.parse(@response.body)
    assert_equal [], r
  end
end
