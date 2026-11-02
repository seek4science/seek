class McpController < ApplicationController
  before_action :only_post
  after_action :set_content_type

  def handle
    server = MCP::Server.new(
      name: 'seek_mcp_server', # TODO: Make this configurable
      title: "#{Seek::Config.instance_name} MCP",
      version: Seek::Version::APP_VERSION,
      tools: tools,
      server_context: { user_id: current_user&.id },
    )

    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server, dns_rebinding_protection: false, stateless: true)

    status, headers, body = transport.handle_request(request)

    render(json: body.first, status: status, headers: headers)
  end

  private

  def tools
    [Tools::SearchTool]
  end

  def only_post
    head :method_not_allowed unless request.post?
  end

  def set_content_type
    # Needed because otherwise it wrongly gets the JSON-API MIME type
    self.content_type = "application/json" if content_type&.start_with?('application/vnd.api+json')
  end
end