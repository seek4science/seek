class McpController < ApplicationController
  before_action :check_enabled
  before_action :only_post
  api_actions :handle
  after_action :set_content_type

  def handle
    server = MCP::Server.new(
      name: Seek::Config.mcp_server_id,
      title: Seek::Config.mcp_server_title,
      version: Seek::Version::APP_VERSION.to_s,
      tools: tools,
      server_context: { user_id: current_user&.id },
    )

    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server, stateless: true, serve_subscriptions_listen: false)

    status, headers, body = transport.handle_request(request)

    render(json: body.first, status: status, headers: headers)
  end

  private

  def tools
    [Tools::SearchTool].select(&:enabled?).map(&:build)
  end

  def only_post
    head :method_not_allowed unless request.post?
  end

  def set_content_type
    # Needed because otherwise it wrongly gets the JSON-API MIME type
    self.content_type = 'application/json' if content_type&.start_with?('application/vnd.api+json')
  end

  def check_enabled
    head :not_found unless Seek::Config.mcp_server_enabled
  end
end