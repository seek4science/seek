require 'test_helper'

class LifeMonitorOauthClientTest < ActiveSupport::TestCase
  test 'get access token' do
    client = LifeMonitor::Oauth2::Client.new('gacpysE92DHZMGc3PU8M3Gei', 'oEru7pekI75cQ6aGXhSGSzcwiL8O03Xhd1LaS2jkfH3uwTjq', 'https://localhost:8000/')
    VCR.use_cassette('life_monitor/get_token') do
      token = client.get_token
      assert token.length > 30
    end
  end
end
