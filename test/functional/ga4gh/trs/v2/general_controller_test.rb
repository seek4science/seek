require 'test_helper'
module Ga4gh
  module Trs
    module V2
      class GeneralControllerTest < ActionController::TestCase
        include AuthenticatedTestHelper

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

        test 'should get organizations' do
          Project.delete_all
          FactoryBot.create(:project, title: 'Project A')
          FactoryBot.create(:project, title: 'Project B')
          FactoryBot.create(:project, title: 'Project C')
          get :organizations

          assert_response :success
          r = JSON.parse(@response.body)
          assert_equal 3, r.length
          assert_includes r, 'Project A'
          assert_includes r, 'Project B'
          assert_includes r, 'Project C'
        end
      end
    end
  end
end
