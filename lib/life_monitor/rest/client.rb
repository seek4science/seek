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
        perform("/workflows/#{workflow_version.parent.uuid}/status", :get, {
          version: workflow_version.version
        })
      end

      def submit(workflow_version)
        perform("/registries/current/workflows", :post,
                content_type: :json,
                body: {
                    identifier: workflow_version.parent.id.to_s,
                    version: workflow_version.version.to_s,
                    public: workflow_version.parent.can_download?(nil)
                })
      end

      def update(workflow_version)
        perform("/workflows/#{workflow_version.parent.uuid}/versions/#{workflow_version.version}", :put,
                content_type: :json,
                body: {
                    name: workflow_version.title,
                    version: workflow_version.version.to_s
                })
      end

      def exists?(workflow_version)
        begin
          response = perform("/workflows/#{workflow_version.parent.uuid}/versions", :get)
          response['versions'].any? { |v| v['version'] == workflow_version.version.to_s }
        rescue RestClient::NotFound
          false
        end
      end

      # Not yet implemented on LifeMonitor side
      def list_workflows
        perform("/registries/current/workflows?status=true&versions=true", :get, content_type: :json)
      end

      def self.status_page_url(workflow, base: Seek::Config.life_monitor_url)
        URI.join(base, "/workflow;uuid=#{workflow.uuid}").to_s
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
