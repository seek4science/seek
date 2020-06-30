require 'rest-client'

module Seek
  module WorkflowExtractors
    class CWL < Base
      DIAGRAM_PATH = '/graph/%{format}'
      def self.ro_crate_metadata
        {
            "@id" => "#cwl",
            "@type" => "ComputerLanguage",
            "name" => "Common Workflow Language",
            "alternateName" => "CWL",
            "identifier" => { "@id" => "https://w3id.org/cwl/v1.0/" },
            "url" => { "@id" => "https://www.commonwl.org/" }
        }
      end

      available_diagram_formats(png: 'image/png', svg: 'image/svg+xml', default: :svg)

      def can_render_diagram?
        Seek::Config.cwl_viewer_url.present?
      end

      def diagram(format = self.class.default_digram_format)
        return nil unless Seek::Config.cwl_viewer_url.present?
        content_type = self.class.diagram_formats[format]
        url = URI.join(Seek::Config.cwl_viewer_url, DIAGRAM_PATH % { format: format }).to_s
        RestClient.post(url, @io.read, content_type: 'text/plain', accept: content_type)
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

        packed_cwl_string = `cwltool --pack #{path}`
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
        if cwl.key?('label')
          existing_metadata[:title] = cwl['label']
        end
        if cwl.key?('doc')
          existing_metadata[:description] = cwl['doc']
        end
        if cwl.key?('s:license')
          existing_metadata[:license] = cwl['s:license']
        end

        existing_metadata[:internals] = {}

        existing_metadata[:internals][:inputs] = iterate(cwl['inputs']).map do |id, input|
          { id: id, name: input['label'], description: input['doc'], type: input['type'], default_value: input['default'] }
        end

        existing_metadata[:internals][:outputs] = iterate(cwl['outputs']).map do |id, output|
          { id: id, name: output['label'], description: output['doc'], type: output['type'] }
        end

        existing_metadata[:internals][:steps] = iterate(cwl['steps']).map do |id, step|
          { id: id, name: step['label'], description: step['doc'] }
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
    end
  end
end
