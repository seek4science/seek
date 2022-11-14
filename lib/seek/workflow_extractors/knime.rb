module Seek
  module WorkflowExtractors
    class KNIME < Base
      def self.file_extensions
        ['knwf']
      end

      def metadata
        metadata = super

        metadata.merge(parse_internal_workflow(extract_workflow))

        metadata
      end

      def can_render_diagram?
        !extract_diagram.nil?
      end

      def generate_diagram
        extract_diagram
      end

      private

      def parse_internal_workflow(knime_string)
        metadata = {}
        knime = LibXML::XML::Parser.string(knime_string).parse
        knime.root.namespaces.default_prefix = 'k'

        title = knime.find('/k:config/k:entry[not(@isnull="true")][@key="name"]/@value').first&.value
        if title.present?
          metadata[:title] = title.to_s
        else
          metadata[:warnings] ||= []
          metadata[:warnings] << 'Unable to determine title of workflow'
        end

        description = knime.find('/k:config/k:entry[not(@isnull="true")][@key="customDescription"]/@value').first&.value
        metadata[:description] = description if description.present?

        metadata
      end

      def extract_workflow
        return @_workflow if defined? @_workflow
        extract
        @_workflow
      end

      def extract_diagram
        return @_diagram if defined? @_diagram
        extract
        @_diagram
      end

      def extract
        @_workflow = nil
        @_diagram = nil
        begin
          t = Tempfile.new('temp.zip')
          t.binmode
          t.write(@io.read)
          t.rewind
          Zip::File.open(t) do |zf|
            wf = zf.entries.detect { |e| e.name =~ /^[^\/]+\/workflow\.knime$/ }
            @_workflow = wf.get_input_stream.read if wf
            dia = zf.entries.detect { |e| e.name =~ /^[^\/]+\/workflow\.svg$/ }
            @_diagram = dia.get_input_stream.read if dia
          end
        rescue Zip::Error
        end
      end
    end
  end
end
