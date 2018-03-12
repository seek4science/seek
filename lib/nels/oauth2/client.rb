require 'json'
require 'rest-client'

module Nels
  module Oauth2
    class Client
      def initialize(client_id, client_secret, redirect_uri, state)
        @client_id = client_id
        @client_secret = client_secret
        @redirect_uri = redirect_uri
        @state = state
      end

      def authorize_url
        url = URI("#{Seek::Config.nels_oauth_url}/authorize")

        url.query = {
            scope: 'user',
            state: @state,
            redirect_uri: @redirect_uri,
            response_type: 'code',
            client_id: @client_id
        }.to_param

        url.to_s
      end

      def get_token(code)
        url = URI("#{Seek::Config.nels_oauth_url}/token")

        body = {
            client_id: @client_id,
            client_secret: @client_secret,
            grant_type: 'authorization_code',
            code: code,
            state: @state,
            redirect_uri: @redirect_uri # Not sure why this is needed, but the request fails otherwise
        }

        JSON.parse RestClient.post(url.to_s, body.to_json, content_type: :json)
      end
    end
  end
end
