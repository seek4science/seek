require 'rest-client'
require 'uri'

module Nels
  module Rest
    class Client
      BASE = 'https://test-fe.cbu.uib.no/nels-api'

      attr_reader :base, :access_token

      def initialize(access_token, base = BASE)
        @access_token = access_token
        @base = RestClient::Resource.new(base)
      end

      def user_info
        perform('user-info', :get)
      end

      def projects
        perform('sbi/projects', :get)
      end

      private

      def perform(path, method, opts = {})
        opts[:content_type] ||= :json
        opts[:Authorization] = "Bearer #{@access_token}"
        body = opts.delete(:body)
        args = [method]
        if body
          body = body.to_json if content_type == :json
          args << body
        end
        args << opts

        response = base[path].send(*args)

        JSON.parse(response) unless response.empty?
      end

    end
  end
end
