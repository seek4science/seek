require 'rest-client'
require 'uri'

module LifeMonitor
  module Rest
    class Client
      include Seek::Util.routes

      attr_reader :base, :access_token

      attr_accessor :verify_ssl

      def initialize(access_token, base = nil)
        @base = base || Seek::Config.life_monitor_url
        @access_token = access_token
        @verify_ssl = Rails.env.production? || !@base.start_with?('https://localhost')
      end

      def status(workflow_version)
        perform("/workflows/#{workflow_version.workflow.uuid}/status", :get, {
          version: workflow_version.version
        })
      end

      def submit(workflow_version)
        perform("/users/#{workflow_version.contributor.id}/workflows", :post,
                content_type: :json,
                body: {
                    uuid: workflow_version.workflow.uuid,
                    version: workflow_version.version.to_s,
                    roc_link: ro_crate_workflow_url(workflow_version.workflow, version: workflow_version.version),
                    name: workflow_version.workflow.title
                })
      end

      def exists?(workflow_version)
        begin
          perform("/workflows/#{workflow_version.workflow.uuid}", :get, params: {
            version: workflow_version.version
          })
          true
        rescue RestClient::NotFound
          false
        end
      end

      private

      def perform(path, method, opts = {})
        opts[:content_type] ||= :json
        opts[:Authorization] = "Bearer #{@access_token}"
        body = opts.delete(:body)
        if body
          body = body.to_json if opts[:content_type] == :json
        end

        url = URI.join(base, path)

        response = RestClient::Request.execute(method: method,
                                               url: url.to_s,
                                               payload: body,
                                               headers: opts,
                                               verify_ssl: @verify_ssl)

        return response if opts[:skip_parse]

        JSON.parse(response) unless response.empty?
      end

    end
  end
end
