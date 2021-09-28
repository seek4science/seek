require 'rest-client'
require 'uri'

module LifeMonitor
  module Rest
    class Client
      include Rails.application.routes.url_helpers

      attr_reader :base, :access_token

      attr_accessor :verify_ssl

      def initialize(access_token, base = nil)
        @base = base || Seek::Config.life_monitor_url
        @access_token = access_token
        @verify_ssl = Rails.env.production? || !@base.start_with?('https://localhost')
      end

      def status(workflow_version)
        perform("/workflows/#{workflow_version.workflow.uuid}/#{workflow_version.version}/status", :get)
      end

      def submit(workflow_version)
        perform("/workflows", :post,
                content_type: :json,
                body: {
                    uuid: workflow_version.workflow.uuid,
                    version: workflow_version.version.to_s,
                    roc_link: ro_crate_workflow_url(workflow_version.workflow, version: workflow_version.version,
                                                    host: Seek::Config.host_with_port,
                                                    protocol: Seek::Config.host_scheme),
                    name: workflow_version.workflow.title,
                    submitter_id: workflow_version.contributor.id.to_s
                })
      end

      def replace(workflow_version)
        raise 'not implemented' # Wait for this to be implemented by LifeMonitor
        perform("/workflows/#{workflow_version.workflow.uuid}/#{workflow_version.version}", :put,
                content_type: :json,
                body: {
                    uuid: workflow_version.workflow.uuid,
                    version: workflow_version.version.to_s,
                    roc_link: ro_crate_workflow_url(workflow_version.workflow, version: workflow_version.version,
                                                    host: Seek::Config.host_with_port,
                                                    protocol: Seek::Config.host_scheme),
                    name: workflow_version.workflow.title,
                    submitter_id: workflow_version.contributor.id.to_s
                })
      end

      def exists?(workflow_version)
        begin
          perform("/workflows/#{workflow_version.workflow.uuid}/#{workflow_version.version}", :get)
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
