require 'test_helper'

class ExceptionForwarderTest < ActiveSupport::TestCase

  test 'default data' do
    p = Factory(:person)
    User.with_current_user(p.user) do
      with_config_value(:site_base_host, 'http://fish.com') do
        data = Seek::Errors::ExceptionForwarder.default_data
        user = data[:user]
        expected = {id: p.user.id,
                    login:p.user.login,
                    created_at:p.user.created_at}
        assert_equal expected,user
        person = data[:person]
        expected = {id: p.id,
                    name:p.title,
                    email:p.email,
                    created_at:p.created_at}
        assert_equal expected, person
        assert_equal 'http://fish.com',data[:site_host]
      end
    end
  end

  test 'send notification' do
    with_config_value(:email_enabled, true) do
      assert_enqueued_emails 1 do
        Seek::Errors::ExceptionForwarder.send_notification(StandardError.new('test'),data:{})
      end
    end
  end

end