require 'test_helper'
module Ga4gh
  module Trs
    module V2
      class ToolsControllerTest < ActionController::TestCase
        include AuthenticatedTestHelper
        fixtures :users, :people

        test 'should not work if disabled' do
          with_config_value(:ga4gh_trs_api_enabled, false) do
            get :index
            assert_response :not_found
          end
        end

        test 'should list workflows as tools' do
          workflow = Factory(:workflow, policy: Factory(:public_policy))
          assert workflow.can_view?

          get :index

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert ids.include?(workflow.id.to_s)
        end

        test 'should not list private workflows' do
          workflow = Factory(:workflow, policy: Factory(:private_policy))
          refute workflow.can_view?

          get :index

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          refute ids.include?(workflow.id.to_s)
        end

        test 'should get workflow as tool' do
          workflow = Factory(:workflow, policy: Factory(:public_policy))
          assert workflow.can_view?

          get :show, params: { id: workflow.id }

          assert_response :success
        end

        test 'should throw not found error in correct format' do
          get :show, params: { id: (Workflow.maximum(:id) || 100) + 99}

          r = JSON.parse(@response.body)
          assert_response :not_found
          assert_equal 404, r['code']
          assert r['message'].include?("Couldn't find")
        end

        test 'should throw not found error for private workflow' do
          workflow = Factory(:workflow, policy: Factory(:private_policy))

          get :show, params: { id: workflow.id }

          r = JSON.parse(@response.body)
          assert_response :not_found
          assert_equal 404, r['code']
          assert r['message'].include?("Couldn't find")
        end

        # Filtering
        test 'should filter workflows by name' do
          w1 = Factory(:workflow, title: 'Cool Workflow', policy: Factory(:public_policy))
          w2 = Factory(:workflow, title: 'Hot Workflow', policy: Factory(:public_policy))
          w3 = Factory(:workflow, title: 'Cooler Workflow', policy: Factory(:public_policy))

          get :index, params: { name: 'cool' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 2, ids.length
          assert ids.include?(w1.id.to_s)
          assert ids.include?(w3.id.to_s)

          get :index, params: { name: 'flow' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 3, ids.length
          assert ids.include?(w1.id.to_s)
          assert ids.include?(w2.id.to_s)
          assert ids.include?(w3.id.to_s)

          get :index, params: { name: 'fish' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 0, ids.length
        end

        test 'should filter workflows by description' do
          w1 = Factory(:workflow, description: 'A very cool Workflow indeed!', policy: Factory(:public_policy))
          w2 = Factory(:workflow, description: 'A very hot Workflow indeed!', policy: Factory(:public_policy))
          w3 = Factory(:workflow, description: 'A very cooler Workflow indeed!', policy: Factory(:public_policy))

          get :index, params: { description: 'cool' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 2, ids.length
          assert ids.include?(w1.id.to_s)
          assert ids.include?(w3.id.to_s)

          get :index, params: { description: 'hot' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 1, ids.length
          assert ids.include?(w2.id.to_s)

          get :index, params: { description: 'warm' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 0, ids.length
        end

        test 'should filter workflows by toolClass' do
          w1 = Factory(:workflow, policy: Factory(:public_policy))
          w2 = Factory(:workflow, policy: Factory(:public_policy))
          w3 = Factory(:workflow, policy: Factory(:public_policy))

          get :index, params: { toolClass: 'Workflow' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 3, ids.length
          assert ids.include?(w1.id.to_s)
          assert ids.include?(w2.id.to_s)
          assert ids.include?(w3.id.to_s)

          get :index, params: { toolClass: 'Hammer' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 0, ids.length
        end

        test 'should filter workflows by descriptorType' do
          w1 = Factory(:cwl_workflow, policy: Factory(:public_policy))
          w2 = Factory(:existing_galaxy_ro_crate_workflow, policy: Factory(:public_policy))
          w3 = Factory(:nf_core_ro_crate_workflow, policy: Factory(:public_policy))

          get :index, params: { descriptorType: 'CWL' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 1, ids.length
          assert ids.include?(w1.id.to_s)

          get :index, params: { descriptorType: 'GALAXY' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 1, ids.length
          assert ids.include?(w2.id.to_s)

          get :index, params: { descriptorType: 'NFL' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 1, ids.length
          assert ids.include?(w3.id.to_s)

          get :index, params: { descriptorType: 'WDL' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 0, ids.length
        end

        test 'should filter workflows by organization' do
          p1 = Factory(:project, title: 'MegaWorkflows')
          p2 = Factory(:project, title: 'CovidSux')
          w1 = Factory(:workflow, projects: [p1], policy: Factory(:public_policy))
          w2 = Factory(:workflow, projects: [p2], policy: Factory(:public_policy))
          w3 = Factory(:workflow, projects: [p1, p2], policy: Factory(:public_policy))

          get :index, params: { organization: 'CovidSux' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 2, ids.length
          assert ids.include?(w2.id.to_s)
          assert ids.include?(w3.id.to_s)

          get :index, params: { organization: 'MegaWorkflows' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 2, ids.length
          assert ids.include?(w1.id.to_s)
          assert ids.include?(w3.id.to_s)

          get :index, params: { organization: 'Hello' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 0, ids.length
        end

        test 'should filter workflows by author' do
          p1 = Factory(:person, first_name: 'Bob', last_name: 'Lastname')
          p2 = Factory(:person, first_name: 'Jane', last_name: 'Lastname')
          w1 = Factory(:workflow, creators: [p1], other_creators: 'Sandra Testington, John Johnson', policy: Factory(:public_policy))
          w2 = Factory(:workflow, creators: [p2], other_creators: 'Sandra Testington, Ivan Ivanov', policy: Factory(:public_policy))
          w3 = Factory(:workflow, creators: [p1, p2], other_creators: 'Bob Lastname', policy: Factory(:public_policy))
          w4 = Factory(:workflow, creators: [], other_creators: 'Bob Lastname', policy: Factory(:public_policy))

          get :index, params: { author: 'Bob Lastname' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 3, ids.length
          assert ids.include?(w1.id.to_s)
          assert ids.include?(w3.id.to_s)
          assert ids.include?(w4.id.to_s)

          get :index, params: { author: 'Jane Lastname' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 2, ids.length
          assert ids.include?(w2.id.to_s)
          assert ids.include?(w3.id.to_s)

          get :index, params: { author: 'Ivan Ivanov' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 1, ids.length
          assert ids.include?(w2.id.to_s)

          get :index, params: { author: 'Sandra Testington' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 2, ids.length
          assert ids.include?(w1.id.to_s)
          assert ids.include?(w2.id.to_s)

          get :index, params: { author: 'Sandra Johnson' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 0, ids.length
        end

        test 'should filter workflows by "checker"' do
          w1 = Factory(:workflow, policy: Factory(:public_policy))
          w2 = Factory(:workflow, policy: Factory(:public_policy))
          w3 = Factory(:workflow, policy: Factory(:public_policy))

          get :index, params: { checker: 'true' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 0, ids.length

          get :index, params: { checker: 'false' }
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 3, ids.length
          assert ids.include?(w1.id.to_s)
          assert ids.include?(w2.id.to_s)
          assert ids.include?(w3.id.to_s)
        end

        test 'should filter by multiple criterion' do
          p1 = Factory(:project, title: 'CovidBad')
          p2 = Factory(:project, title: 'WorkflowsGood')
          cwl1 = Factory(:cwl_workflow, title: 'Covid fixer', projects: [p1], policy: Factory(:public_policy))
          cwl2 = Factory(:cwl_workflow, title: 'Thing doer', projects: [p2], policy: Factory(:public_policy))
          gal1 = Factory(:existing_galaxy_ro_crate_workflow, title: 'Stop covid', projects: [p1],  policy: Factory(:public_policy))
          gal2 = Factory(:existing_galaxy_ro_crate_workflow, title: 'Concat 2 strings', projects: [p2], policy: Factory(:public_policy))
          nfl1 = Factory(:nf_core_ro_crate_workflow, title: 'Covid sim', policy: Factory(:public_policy))
          nfl2 = Factory(:nf_core_ro_crate_workflow, title: 'RNA something', policy: Factory(:public_policy))

          get :index, params: { name: 'covid', descriptorType: 'NFL' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 1, ids.length
          assert ids.include?(nfl1.id.to_s)

          get :index, params: { descriptorType: 'CWL', organization: 'CovidBad' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 1, ids.length
          assert ids.include?(cwl1.id.to_s)

          get :index, params: { name: 'covid', organization: 'CovidBad' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 2, ids.length
          assert ids.include?(cwl1.id.to_s)
          assert ids.include?(gal1.id.to_s)

          get :index, params: { name: 'covid', organization: 'CovidBad', descriptorType: 'NFL' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 0, ids.length
        end

        test 'should paginate tools' do
          p1 = Factory(:project, title: 'CovidBad')
          p2 = Factory(:project, title: 'WorkflowsGood')
          cwl1 = Factory(:cwl_workflow, title: 'Covid fixer', projects: [p1], policy: Factory(:public_policy))
          cwl2 = Factory(:cwl_workflow, title: 'Thing doer', projects: [p2], policy: Factory(:public_policy))
          gal1 = Factory(:existing_galaxy_ro_crate_workflow, title: 'Stop covid', projects: [p1],  policy: Factory(:public_policy))
          gal2 = Factory(:existing_galaxy_ro_crate_workflow, title: 'Concat 2 strings', projects: [p2], policy: Factory(:public_policy))
          nfl1 = Factory(:nf_core_ro_crate_workflow, title: 'Covid sim', policy: Factory(:public_policy))
          nfl2 = Factory(:nf_core_ro_crate_workflow, title: 'RNA something', policy: Factory(:public_policy))

          count = Workflow.count
          assert_equal 6, count

          get :index

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 6, ids.length
          assert_equal ga4gh_trs_v2_tools_url, @response.headers['self_link']
          assert_nil @response.headers['next_page']
          assert_equal ga4gh_trs_v2_tools_url, @response.headers['last_page']
          assert_equal 1000, @response.headers['current_limit']
          assert_nil @response.headers['current_offset']

          get :index, params: { limit: 1 }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 1, ids.length
          assert_equal cwl1.id.to_s, ids.first
          assert_equal ga4gh_trs_v2_tools_url(limit: 1), @response.headers['self_link']
          assert_equal ga4gh_trs_v2_tools_url(limit: 1, offset: 1), @response.headers['next_page']
          assert_equal ga4gh_trs_v2_tools_url(limit: 1, offset: 5), @response.headers['last_page']
          assert_equal 1, @response.headers['current_limit']
          assert_nil @response.headers['current_offset']

          get :index, params: { limit: 2, offset: 1 }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 2, ids.length
          assert_equal cwl2.id.to_s, ids.first
          assert_equal gal1.id.to_s, ids.last
          assert_equal ga4gh_trs_v2_tools_url(limit: 2, offset: 1), @response.headers['self_link']
          assert_equal ga4gh_trs_v2_tools_url(limit: 2, offset: 3), @response.headers['next_page']
          assert_equal ga4gh_trs_v2_tools_url(limit: 2, offset: 3), @response.headers['last_page']
          assert_equal 2, @response.headers['current_limit']
          assert_equal 1, @response.headers['current_offset']

          get :index, params: { offset: 1, descriptorType: 'NFL' }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_equal 1, ids.length
          assert_equal nfl2.id.to_s, ids.first
          assert_equal ga4gh_trs_v2_tools_url(offset: 1, descriptorType: 'NFL'), @response.headers['self_link']
          assert_nil @response.headers['next_page']
          assert_equal ga4gh_trs_v2_tools_url(descriptorType: 'NFL'), @response.headers['last_page']
          assert_equal 1000, @response.headers['current_limit']
          assert_equal 1, @response.headers['current_offset']
        end
      end
    end
  end
end
