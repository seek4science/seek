require 'json'
require 'rest-client'

module LifeMonitor
  module Oauth2
    class Client
      # Possible scopes:
      #  registry.info
      #  registry.user
      #  registry.workflow.read
      #  registry.workflow.write
      #  registry.user.workflow.read
      #  registry.user.workflow.write
      #  workflow.read
      #  workflow.write
      #  testingService.read
      #  testingService.write
      #  user.profile
      #  user.workflow.read

      SCOPES = %w[registry.info registry.user registry.workflow.read registry.workflow.write
                  registry.user.workflow.read registry.user.workflow.write workflow.read workflow.write
                  testingService.read testingService.write user.profile user.workflow.read]

      attr_accessor :verify_ssl

      def initialize(client_id = nil, client_secret = nil, base = nil, scopes = SCOPES)
        @base = base || Seek::Config.life_monitor_url
        @client_id = client_id || Seek::Config.life_monitor_client_id
        @client_secret = client_secret || Seek::Config.life_monitor_client_secret
        @scopes = scopes
        @verify_ssl = Rails.env.production? || !@base.start_with?('https://localhost')
      end

      def get_token
        url = URI.join(@base, '/oauth2/token')

        body = {
            client_id: @client_id,
            client_secret: @client_secret,
            grant_type: 'client_credentials',
            scope: @scopes.join(' ')
        }

        res = RestClient::Request.execute(method: :post, url: url.to_s, payload: body, verify_ssl: @verify_ssl)
        JSON.parse(res)['access_token']
      end
    end
  end
end
