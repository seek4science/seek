module Seek
  module WorkflowExtractors
    class Base
      NULL_CLASS_METADATA = {
          "@id" => "#workflow_type",
          "@type" => "ComputerLanguage",
          "name" => "Unrecognized Workflow Type"
      }

      def initialize(io)
        @io = io.is_a?(String) ? StringIO.new(io) : io
      end

      def metadata
        { }
      end

      def has_tests?
        false
      end

      def can_render_diagram?
        false
      end

      def generate_diagram
        nil
      end

      def diagram_extension
        'svg'
      end

      def self.workflow_class
        WorkflowClass.find_by_key(name.demodulize.underscore)
      end

      def self.file_extensions
        []
      end
    end
  end
end
