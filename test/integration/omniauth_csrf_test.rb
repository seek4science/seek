require 'test_helper'

# Make sure that https://nvd.nist.gov/vuln/detail/CVE-2015-9284 is mitigated
# Adapted from: https://gist.github.com/CHTJonas/70cd9ec5fcffa6ca5bae0e04ec51d174
class OmniauthCsrfTest < ActionDispatch::IntegrationTest
  setup do
    ActionController::Base.allow_forgery_protection = true
    OmniAuth.config.test_mode = false
  end

  test 'should not accept GET requests to OmniAuth endpoint' do
    assert_raises(ActionController::RoutingError) do
      get '/auth/elixir_aai'
    end
  end

  test 'should not accept POST requests with invalid CSRF tokens to OmniAuth endpoint' do
    post '/auth/elixir_aai'
    assert_redirected_to(omniauth_failure_path(strategy: 'elixir_aai', message: 'ActionController::InvalidAuthenticityToken'))
  end

  teardown do
    ActionController::Base.allow_forgery_protection = false
    OmniAuth.config.test_mode = true
  end
end
