require 'test_helper'
require 'minitest/mock'

class ExceptionNotificationTest < ActionDispatch::IntegrationTest
  test 'filters sensitive parameters out of exception notifications' do
    with_config_values(email_enabled: true,
                       exception_notification_enabled: true,
                       exception_notification_recipients: 'no-reply@sysmo-db.org') do
      emails = capture_emails do
        User.stub(:admin_logged_in?, true) do
          Rails.application.config.stub(:consider_all_requests_local, false) do
            get fail_path, params: { http_code: '500',
                                     password: 'unique_string_2',
                                     email: 'unique_string_3',
                                     unfiltered_param: 'unique_string_4',
                                     author: 'unique_string_5'
            }, as: :json, headers: {
              'Accept' => 'application/vnd.api+json',
              'Authorization' => 'Token unique_string_1'
            }
          end
        end
      end

      assert_equal 1, emails.length
      email = emails.last
      body = email.body.to_s

      assert_includes body, 'A NoMethodError occurred in fail'
      assert_not_includes body, 'unique_string_1'
      assert_not_includes body, 'unique_string_2'
      assert_not_includes body, 'unique_string_3'
      assert_includes body, 'unique_string_4'
      assert_includes body, 'unique_string_5'
      assert_match /HTTP_AUTHORIZATION\s+: \[FILTERED\]/, body
    end
  end
end