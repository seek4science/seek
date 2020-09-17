require 'test_helper'

class Ga4ghTrsApiTest < ActionDispatch::IntegrationTest
  include AuthenticatedTestHelper

  fixtures :users, :people

  test 'should not work if disabled' do
    with_config_value(:ga4gh_trs_api_enabled, false) do
      get ga4gh_trs_v2_tools_path
      assert_response :forbidden
    end
  end

  test 'should list workflows as tools' do
    workflow = Factory(:workflow, title: 'my workflow', policy: Factory(:public_policy))

    assert workflow.can_view?
    get ga4gh_trs_v2_tools_path
    assert_response :success
    ids = JSON.parse(@response.body).map { |t| t['id'] }
    assert ids.include?(workflow.id.to_s)
  end

  test 'should not list private workflows' do
    workflow = Factory(:workflow, title: 'my workflow', policy: Factory(:private_policy))

    refute workflow.can_view?
    get ga4gh_trs_v2_tools_path
    assert_response :success
    ids = JSON.parse(@response.body).map { |t| t['id'] }
    refute ids.include?(workflow.id.to_s)
  end
end
