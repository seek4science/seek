require 'test_helper'

class LifeMonitorOauthClientTest < ActiveSupport::TestCase
  test 'get access token' do
    client = LifeMonitor::Oauth2::Client.new('fWWLbOAw0pLlRKIWOQlkO4b4', 'Ne1kK6NljWRayqzDfgMWBfVplkRGZto6MCjdfhK1jY7r8RVp', 'https://localhost:8443/')
    VCR.use_cassette('life_monitor/get_token') do
      token = client.get_token
      assert token.length > 30
    end
  end
end
