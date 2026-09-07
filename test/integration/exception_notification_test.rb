require 'test_helper'
require 'minitest/mock'

class ExceptionNotificationTest < ActionDispatch::IntegrationTest
  test 'filters sensitive parameters out of exception notifications' do
    assert_equal 0, ActionMailer::Base.deliveries.length

    User.stub(:admin_logged_in?, true) do
      with_config_value(:email_enabled, true) do
        with_config_value(:exception_notification_enabled, true) do
          with_config_value(:exception_notification_recipients, 'no-reply@sysmo-db.org') do
            with_config_value(:auth_lookup_enabled, true) do
              headers = {
                'Accept' => 'application/vnd.api+json',
                'Authorization' => 'Token unique_string_1'
              }

              Rails.application.config.stub(:consider_all_requests_local, false) do
                get fail_path, params: { http_code: '500',
                                         password: 'unique_string_2',
                                         email: 'unique_string_3',
                                         unfiltered_param: 'unique_string_4' }, as: :json, headers: headers
              end

              assert_equal 1, ActionMailer::Base.deliveries.length # Exception notification

              email = ActionMailer::Base.deliveries.last
              body = email.body.to_s

              assert_includes body, 'A NoMethodError occurred in fail'
              assert_not_includes body, 'unique_string_1'
              assert_not_includes body, 'unique_string_2'
              assert_not_includes body, 'unique_string_3'
              assert_includes body, 'unique_string_4'
              assert_match /HTTP_AUTHORIZATION\s+: \[FILTERED\]/, body
            end
          end
        end
      end
    end
  end
end