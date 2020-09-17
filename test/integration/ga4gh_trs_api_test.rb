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
    workflow = Factory(:workflow, title: 'my workflow', policy: Factory(:public_policy))

    assert workflow.can_view?
    get "/ga4gh/trs/v2/tools"
    assert_response :success
    ids = JSON.parse(@response.body).map { |t| t['id'] }
    assert ids.include?(workflow.id.to_s)
  end

  test 'should not list private workflows' do
    workflow = Factory(:workflow, title: 'my workflow', policy: Factory(:private_policy))

    refute workflow.can_view?
    get "/ga4gh/trs/v2/tools"
    assert_response :success
    ids = JSON.parse(@response.body).map { |t| t['id'] }
    refute ids.include?(workflow.id.to_s)
  end

  test 'should get workflow as tool' do
    workflow = Factory(:workflow, title: 'my workflow', policy: Factory(:public_policy))

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
    workflow = Factory(:workflow, title: 'my workflow', policy: Factory(:private_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}"
    r = JSON.parse(@response.body)
    assert_response :not_found
    assert_equal 404, r['code']
    assert r['message'].include?("Couldn't find")
  end

  test 'should list workflow versions as tool versions' do
    workflow = Factory(:workflow, title: 'my workflow', policy: Factory(:public_policy))
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
    workflow = Factory(:workflow, title: 'my workflow', policy: Factory(:public_policy))

    assert 1, workflow.reload.versions.count
    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1"
    assert_response :success
  end

  test 'should list tool version files for correct descriptor' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, title: 'my workflow', policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/GALAXY/files"
    assert_response :success
    r = JSON.parse(@response.body)
    assert_equal 3, r.length
    galaxy = r.detect { |f| f['path'] == 'Genomics-1-PreProcessing_without_downloading_from_SRA.ga' }
    diagram = r.detect { |f| f['path'] == 'Genomics-1-PreProcessing_without_downloading_from_SRA.svg' }
    assert galaxy
    assert_equal 'PRIMARY_DESCRIPTOR', galaxy['file_type']
    assert diagram
    assert_equal 'OTHER', diagram['file_type']
  end

  test 'should not list tool version files for wrong descriptor' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, title: 'my workflow', policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/NFL/files"
    assert_response :not_found
  end

  test 'should get main workflow as primary descriptor' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, title: 'my workflow', policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/GALAXY/descriptor"
    assert_response :success
    assert @response.body.include?('a_galaxy_workflow')
  end

  test 'should get descriptor file via relative path' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, title: 'my workflow', policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/GALAXY/descriptor/Genomics-1-PreProcessing_without_downloading_from_SRA.ga"
    assert_response :success
    assert_equal 'application/json; charset=utf-8', @response.headers['Content-Type']
    assert @response.body.include?('a_galaxy_workflow')
  end

  test 'should get plain descriptor file via relative path' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, title: 'my workflow', policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/PLAIN_GALAXY/descriptor/Genomics-1-PreProcessing_without_downloading_from_SRA.svg"
    assert_response :success
    assert_equal 'application/json; charset=utf-8', @response.headers['Content-Type']
    assert @response.body.include?('<!DOCTYPE svg')
  end

  test 'should 404 on missing descriptor file via relative path' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, title: 'my workflow', policy: Factory(:public_policy))

    get "/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/GALAXY/descriptor/../.."
    assert_response :not_found
  end
end
