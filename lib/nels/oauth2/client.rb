require 'json'
require 'rest-client'

module Nels
  module Oauth2
    class Client
      AUTH_ENDPOINT = 'https://test-fe.cbu.uib.no/oauth2/'

      def initialize(client_id, redirect_uri)
        @client_id = client_id
        @redirect_uri = redirect_uri
      end

      def authorize_url
        url = URI::join(AUTH_ENDPOINT, 'authorize')

        url.query = {
            scope: 'user',
            redirect_uri: @redirect_uri,
            response_type: 'token',
            client_id: @client_id
        }.to_param

        puts url

        url.to_s
      end
    end
  end
end
