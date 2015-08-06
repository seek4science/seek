require 'json'
require 'rest-client'

module Zenodo
  class OAuth2
    DEFAULT_ENDPOINT = 'https://zenodo.org/oauth'

    def initialize(client_id, client_secret, endpoint = DEFAULT_ENDPOINT)
      @endpoint = endpoint.chomp('/') + '/'
      @client_id = client_id
      @client_secret = client_secret
    end

    # Generates an URL to take the user to Zenodo's client authorization page
    def authorize_url(state, redirect_uri)
      url = URI::join(@endpoint, 'authorize')
      @redirect_uri = redirect_uri

      url.query = {
          scope: 'deposit:write deposit:actions',
          state: state,
          redirect_uri: redirect_uri,
          response_type: 'code',
          client_id: @client_id
      }.to_param

      url.to_s
    end

    # Performs a POST request to exchange the authorization code for an access token
    def get_token(code, redirect_uri = nil)
      url = URI::join(@endpoint, 'token')
      redirect_uri ||= @redirect_uri

      body = {
          client_id: @client_id,
          client_secret: @client_secret,
          grant_type: 'authorization_code',
          code: code,
          redirect_uri: redirect_uri # Not sure why this is needed, but the request fails otherwise
      }

      json = RestClient.post(url.to_s, body)
      JSON.parse(json)["access_token"]
    end
  end
end
