require 'rest-client'

module Seek
  module WorkflowExtractors
    class CWL < Base
      DIAGRAM_PATH = '/graph/%{format}'
      ABSTRACT_CWL_METADATA = {
          "@id" => "#cwl",
          "@type" => "ComputerLanguage",
          "name" => "Common Workflow Language",
          "alternateName" => "CWL",
          "identifier" => { "@id" => "https://w3id.org/cwl/v1.0/" },
          "url" => { "@id" => "https://www.commonwl.org/" }
      }

      available_diagram_formats(png: 'image/png', svg: 'image/svg+xml', default: :svg)

      def self.file_extensions
        ['cwl']
      end

      def can_render_diagram?
        Seek::Config.cwl_viewer_url.present?
      end

      def generate_diagram(format = self.class.default_digram_format)
        begin
          f = Tempfile.new('diagram.dot')
          wf = WorkflowInternals::Structure.new(metadata[:internals])
          Seek::WorkflowExtractors::CwlDotGenerator.new(f).write_graph(wf)
          f.rewind
          `cat #{f.path} | dot -T#{format}`
        rescue RestClient::Exception => e
          nil
        end
      end

      def metadata
        meta = super
        if @io.is_a?(Pathname)
          cwl_string = nil
          path = @io.to_s
        elsif @io.respond_to?('path')
          cwl_string = nil
          path = @io.path
        else
          cwl_string = @io.read
          f = Tempfile.new('cwl')
          f.binmode
          f.write(cwl_string)
          f.rewind
          path = f.path
        end

        packed_cwl_string = `cwltool --quiet --pack #{path}`
        if $?.success?
          cwl_string = packed_cwl_string
        else
          cwl_string ||= @io.read
          Rails.logger.error('CWL packing failed, using given CWL instead.')
        end

        parse_metadata(meta, cwl_string)

        meta
      end

      private

      def parse_metadata(existing_metadata, yaml_or_json_string)
        cwl = YAML.load(yaml_or_json_string)
        cwl = (cwl['$graph'].detect { |w| w['id'] == '#main' } || {}) if cwl.key?('$graph')

        if cwl.key?('label')
          existing_metadata[:title] = cwl['label']
        end
        if cwl.key?('doc')
          existing_metadata[:description] = cwl['doc']
        end
        if cwl.key?('s:license')
          existing_metadata[:license] = cwl['s:license']
        end

        existing_metadata[:internals] = {
          inputs: [],
          outputs: [],
          steps: [],
          links: []

        }

        existing_metadata[:internals][:inputs] = iterate(cwl['inputs']).map do |id, input|
          { id: id, name: input['label'], description: input['doc'], type: input['type'], default_value: input['default'] }
        end

        existing_metadata[:internals][:outputs] = iterate(cwl['outputs']).map do |id, output|
          { id: id, name: output['label'], description: output['doc'], type: output['type'], sources: output['outputSource'] ? Array(output['outputSource']) : [] }
        end

        existing_metadata[:internals][:steps] = iterate(cwl['steps']).map do |id, step|
          existing_metadata[:internals][:links] += build_links(step['in'], id)
          { id: id, name: step['label'], description: step['doc'], sinks: extract_sinks(step['out']) }
        end
      end

      # Iterate array or map-style lists of things
      # @return [Hash{String => Hash}, Enumerable]
      def iterate(array_or_hash)
        return {} if array_or_hash.nil?
        return to_enum(__method__, array_or_hash) unless block_given?

        if array_or_hash.is_a?(Hash)
          array_or_hash.each do |key, item|
            yield(key, item)
          end
        else
          array_or_hash.each do |item|
            yield(item['id'], item)
          end
        end
      end

      def build_links(obj, sink_id)
        return [] if obj.nil?

        if obj.is_a?(Hash)
          obj.map { |id, source_id| { id: id, source_id: source_id, sink_id: sink_id } }
        else
          Array(obj).flat_map do |s|
            (s['source'].is_a?(Array) ? s['source'] : [s['source']]).map do |source|
              { id: s['id'], source_id: source, sink_id: sink_id, name: s['label'], default_value: s['default'] }
            end
          end
        end
      end

      def extract_sinks(obj)
        obj.is_a?(Hash) ? obj['id'] : obj
      end
    end
  end
end
