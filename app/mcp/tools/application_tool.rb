module Tools
  class ApplicationTool < MCP::Tool
    class << self
      def build
        self
      end

      def enabled?
        true
      end
    end

    def call(*)
      raise NotImplementedError
    end
  end
end
