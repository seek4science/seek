require 'rest-client'
require 'uri'

module LifeMonitor
  class Client
    include Rails.application.routes.url_helpers

    attr_reader :base, :access_token

    def initialize(access_token, base = nil)
      base ||= Seek::Config.life_monitor_url
      @access_token = access_token
      @base = RestClient::Resource.new(base)
    end

    def status(workflow_version)
      perform("/workflows/#{workflow_version.workflow.uuid}/#{workflow_version.version}/status", :get)
    end

    def submit(workflow_version)
      perform("/workflows", :post,
              content_type: :json,
              body: {
                  uuid: workflow_version.workflow.uuid,
                  version: workflow_version.version,
                  roc_link: ro_crate_workflow_path(workflow_version.workflow, version: workflow_version.version),
                  name: workflow_version.workflow.title,
                  submitter_id: person_url(User.current_user.person)
              })
    end

    private

    def perform(path, method, opts = {})
      opts[:content_type] ||= :json
      opts[:Authorization] = "Bearer #{@access_token}"
      body = opts.delete(:body)
      args = [method]
      if body
        body = body.to_json if opts[:content_type] == :json
        args << body
      end
      args << opts

      response = base[path].send(*args)

      return response if opts[:skip_parse]

      JSON.parse(response) unless response.empty?
    end

  end
end
