# Report errors raised while handling MCP requests (including during tool calls), which the MCP gem would otherwise
# swallow. This global reporter is also used by the transport for errors outside of request handling.
# McpController additionally supplies a per-request reporter that includes the request env.
Rails.application.config.to_prepare do
  MCP.configure do |config|
    config.exception_reporter = Seek::Errors::McpExceptionReporter.new
  end
end
