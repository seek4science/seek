module Seek
  module WorkflowExtractors
    class Base
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

      available_diagram_formats(png: 'image/png', default: :png)

      def initialize(io)
        @io = io
      end

      def metadata
        { warnings: [], errors: [] }
      end

      def diagram(format = self.class.default_diagram_format)
        nil
      end
    end
  end
end
