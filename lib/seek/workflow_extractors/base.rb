module Seek
  module WorkflowExtractors
    class Base
      def self.ro_crate_metadata
        {
            "@id" => "#workflow_type",
            "@type" => "ComputerLanguage",
            "name" => "Unrecognized Workflow Type"
        }
      end

      def self.available_diagram_formats(formats)
        formats = formats.with_indifferent_access
        @default_diagram_format = formats.delete(:default) || formats.keys.first.to_sym
        @diagram_formats = formats.freeze
      end

      def self.diagram_formats
        @diagram_formats || superclass.diagram_formats
      end

      def self.default_diagram_format
        @default_diagram_format || superclass.default_diagram_format
      end

      available_diagram_formats(png: 'image/png', svg: 'image/svg+xml', jpg: 'image/jpeg', default: :png)

      def initialize(io)
        @io = io
      end

      def metadata
        { warnings: [], errors: [] }
      end

      def can_render_diagram?
        false
      end

      def diagram(format = default_diagram_format)
        nil
      end

      def default_diagram_format
        self.class.default_diagram_format
      end

      def self.workflow_class
        WorkflowClass.find_by_key(name.demodulize)
      end
    end
  end
end
