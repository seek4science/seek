require 'test_helper'
module Ga4gh
  module Trs
    module V2
      class GeneralControllerTest < ActionController::TestCase
        include AuthenticatedTestHelper
        fixtures :users, :people

        test 'should get service info' do
          get :service_info

          assert_response :success
          r = JSON.parse(@response.body)
          assert_equal Seek::Config.instance_name, r['name']
          assert_equal "mailto:#{Seek::Config.support_email_address}", r['contactUrl']
          assert_equal "test", r['environment']
          assert_equal "localhost", r['id']
        end

        test 'should generate id based on application base url' do
          with_config_value(:site_base_host, 'http://test.host') do
            with_relative_root('/seek/123') do
              get :service_info

              assert_response :success
              r = JSON.parse(@response.body)
              assert_equal "host.test.seek.123", r['id']
            end
          end
        end

        test 'should get tool classes' do
          get :tool_classes

          assert_response :success
          r = JSON.parse(@response.body)
          assert_equal 1, r.length
          assert_equal 'Workflow', r.first['name']
        end
      end
    end
  end
end
