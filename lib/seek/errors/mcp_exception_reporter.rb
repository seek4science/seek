module Seek
  module Errors
    # An `exception_reporter` for the MCP gem. The gem rescues any error raised while handling a request (including
    # inside tool calls) and turns it into a generic JSON-RPC error for the client, passing the original exception to
    # this callable. Without it, the gem's default reporter is a no-op, so errors would be silently swallowed.
    #
    # Exceptions are logged with a backtrace and forwarded to the ExceptionNotifier via ExceptionForwarder.
    class McpExceptionReporter
      def initialize(env: nil)
        @env = env
      end

      # @param exception [Exception] the error (the gem unwraps `RequestHandlerError#original_error` before calling us)
      # @param context [Hash] context supplied by the gem, e.g. `{ request: <JSON-RPC params> }`
      def call(exception, context = {})
        # Client-side errors (e.g. unknown tool, invalid params) are raised as RequestHandlerErrors with a
        # non-internal error type. These are reported back to the client and don't need to be notified.
        if client_error?(exception)
          Rails.logger.info "MCP request error - #{exception.class.name} (#{exception.message})"
          return
        end

        Rails.logger.error "MCP ERROR - #{exception.class.name} (#{exception.message})\n" \
                           "#{Array(exception.backtrace).join("\n")}"
        ExceptionForwarder.send_notification(exception, env: @env, data: { mcp: context })
      end

      private

      def client_error?(exception)
        exception.is_a?(MCP::Server::RequestHandlerError) && exception.original_error.nil? &&
          exception.error_type != :internal_error
      end
    end
  end
end
