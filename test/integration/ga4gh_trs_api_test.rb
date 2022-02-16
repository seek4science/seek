require 'test_helper'
require 'minitest/mock'

class Ga4ghTrsApiTest < ActionDispatch::IntegrationTest
  include AuthenticatedTestHelper

  fixtures :users, :people

  test 'should not work if disabled' do
    with_config_value(:ga4gh_trs_api_enabled, false) do
      get "/ga4gh/trs/v2/tools"
      assert_response :not_found
    end
  end

  test 'should get nested descriptor file via relative path' do
    workflow = Factory(:nf_core_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/NFL/descriptor/docs/images/nfcore-ampliseq_logo.png", headers: { 'Accept' => 'text/plain' }
    assert_response :success
    assert_equal 'text/plain; charset=utf-8', @response.headers['Content-Type']
    assert @response.body.start_with?("\x89PNG\r\n")
  end

  test 'should get containerfile if Dockerfile present' do
    workflow = Factory(:nf_core_ro_crate_workflow, policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/NFL/files"
    assert_response :success
    r = JSON.parse(@response.body)
    assert_equal 32, r.length
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

  test 'should throw spec-compliant JSON error if unexpected error occurs' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))
    Workflow.stub(:find_by_id, -> (_) { raise 'oh no!' }) do
      get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/containerfile"
    end

    assert_response :internal_server_error
    r = JSON.parse(@response.body)
    assert r['message'].include?('An unexpected error')
  end
end
