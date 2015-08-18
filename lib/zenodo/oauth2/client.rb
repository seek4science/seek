require 'json'
require 'rest-client'

module Zenodo
  module Oauth2
    class Client
      DEFAULT_ENDPOINT = 'https://zenodo.org/oauth'

      def initialize(client_id, client_secret, redirect_uri, endpoint = DEFAULT_ENDPOINT)
        @endpoint = endpoint.chomp('/') + '/'
        @client_id = client_id
        @client_secret = client_secret
        @redirect_uri = redirect_uri
      end

      # Generates an URL to take the user to Zenodo's client authorization page
      def authorize_url(state)
        url = URI::join(@endpoint, 'authorize')

        url.query = {
            scope: 'deposit:write deposit:actions',
            state: state,
            redirect_uri: @redirect_uri,
            response_type: 'code',
            client_id: @client_id
        }.to_param

        url.to_s
      end

      # Performs a POST request to exchange the authorization code for an access token
      def get_token(code)
        url = URI::join(@endpoint, 'token')

        body = {
            client_id: @client_id,
            client_secret: @client_secret,
            grant_type: 'authorization_code',
            code: code,
            redirect_uri: @redirect_uri # Not sure why this is needed, but the request fails otherwise
        }

        JSON.parse RestClient.post(url.to_s, body)
      end

      # Performs a POST request to refresh an expired access token using the refresh token
      def refresh(refresh_token)
        url = URI::join(@endpoint, 'token')

        body = {
            client_id: @client_id,
            client_secret: @client_secret,
            grant_type: 'refresh_token',
            refresh_token: refresh_token,
            redirect_uri: @redirect_uri
        }

        JSON.parse RestClient.post(url.to_s, body)
      end
    end
  end
end
