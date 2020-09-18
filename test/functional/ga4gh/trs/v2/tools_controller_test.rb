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
      end
    end
  end
end
