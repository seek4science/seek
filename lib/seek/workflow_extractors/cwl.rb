require 'rest-client'

module Seek
  module WorkflowExtractors
    class CWL < Base
      DIAGRAM_PATH = '/graph/%{format}'

      available_diagram_formats(png: 'image/png', svg: 'image/svg+xml', default: :svg)

      def diagram(format = self.class.default_digram_format)
        return nil unless Seek::Config.cwl_viewer_url.present?
        content_type = self.class.diagram_formats[format]
        url = URI.join(Seek::Config.cwl_viewer_url, DIAGRAM_PATH % { format: format }).to_s
        RestClient.post(url, @io.read, content_type: 'text/plain', accept: content_type)
      end

      def metadata
        metadata = super
        cwl_string = @io.read
        cwl = YAML.load(cwl_string)
        if cwl.key?('label')
          metadata[:title] = cwl['label']
        else
          metadata[:warnings] << 'Unable to determine title of workflow'
        end
        if cwl.key?('doc')
          metadata[:description] = cwl['doc']
        end
        if cwl.key?('s:license')
          metadata[:license] = cwl['s:license']
        end

        metadata[:internals] = {}

        metadata[:internals][:inputs] = iterate(cwl['inputs']).map do |id, input|
          { id: id, name: input['label'], description: input['doc'], type: input['type'], default_value: input['default'] }
        end

        metadata[:internals][:outputs] = iterate(cwl['outputs']).map do |id, output|
          { id: id, name: output['label'], description: output['doc'], type: output['type'] }
        end

        metadata[:internals][:steps] = iterate(cwl['steps']).map do |id, step|
          { id: id, name: step['label'], description: step['doc'] }
        end

        metadata
      end

      private

      # Iterate array or map-style lists of things
      def iterate(array_or_hash)
        return if array_or_hash.nil?
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
