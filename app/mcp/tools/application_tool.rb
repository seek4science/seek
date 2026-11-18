module Tools
  class ApplicationTool < MCP::Tool
    class << self
      def enabled?
        true
      end
    end
  end
end
