require 'open4'
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

      def self.file_extensions
        ['cwl']
      end

      def can_render_diagram?
        true
      end

      def generate_diagram
        begin
          f = Tempfile.new('diagram.dot')
          wf = WorkflowInternals::Structure.new(metadata[:internals])
          Seek::WorkflowExtractors::CwlDotGenerator.new(f).write_graph(wf)
          f.rewind
          out = ''
          err = ''
          Open4.open4('dot -Tsvg') do |pid, stdin, stdout, stderr|
            stdin.puts(f.read)
            stdin.close
            out = stdout.read
            err = stderr.read
            stdout.close
            stderr.close
          end
          Rails.logger.error(err) if err.length > 0
          out
        rescue StandardError => e
          Rails.logger.error(e)
          nil
        end
      end

      def metadata
        return @metadata if @metadata
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

        packed_cwl_string = ''
        err = ''
        status = Open4.popen4(Seek::Util.python_exec("-m cwltool --skip-schemas --quiet --enable-dev --non-strict --pack #{path}")) do |_pid, _stdin, stdout, stderr|
          while (line = stdout.gets) != nil
            packed_cwl_string << line
          end
          err = stderr.read.strip
          stdout.close
          stderr.close
        end

        if status.success? && packed_cwl_string.length.positive?
          cwl_string = packed_cwl_string
        else
          cwl_string ||= @io.read
          Rails.logger.error("CWL packing failed, using given CWL instead. Error was: #{err}")
        end

        parse_metadata(meta, cwl_string)

        @metadata = meta
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

        existing_metadata[:internals][:inputs] = normalise(cwl['inputs']).map do |input|
          { id: input['id'], name: input['label'], description: input['doc'], type: normalise_type(input['type']), default_value: input['default'] }
        end

        existing_metadata[:internals][:outputs] = normalise(cwl['outputs']).map do |output|
          { id: output['id'], name: output['label'], description: output['doc'], type: normalise_type(output['type']), source_ids: output['outputSource'] ? Array(output['outputSource']) : [] }
        end

        existing_metadata[:internals][:steps] = normalise(cwl['steps']).map do |step|
          existing_metadata[:internals][:links] += build_links(step)
          { id: step['id'], name: step['label'], description: step['doc'], sink_ids: extract_sinks(step['out'], step['id']) }
        end
      end

      # Normalise array or map-style lists of things and return an array of hashes.
      # @return [Array{Hash}]
      def normalise(array_or_hash, key_field: 'id', value_field: 'type')
        if array_or_hash.is_a?(Hash)
          o = []
          array_or_hash.each do |key, value|
            if value.is_a?(String)
              o << { key_field => key, value_field => value }
            else
              o << value.merge(key_field => key)
            end
          end
          return o
        end

        array_or_hash || []
      end

      def build_links(step)
        i = step['in']
        return [] if i.nil?

        if i.is_a?(Hash)
          i = i.flat_map do |id, source|
            (source.is_a?(Array) ? source : [source]).map do |s|
              if s.is_a?(String)
                { 'id' => id, 'source' => s }
              else
                s['id'] ||= id
                s
              end
            end
          end
        end

        Array(i).flat_map do |s|
          (s['source'].is_a?(Array) ? s['source'] : [s['source']]).map do |source|
            { id: s['id'], source_id: source, sink_id: step['id'], name: s['label'], default_value: s['default'] }
          end
        end
      end

      def extract_sinks(obj, id)
        obj.map do |o|
          sink = o.is_a?(Hash) ? o['id'] : o
          sink = "#{id}/#{sink}"unless sink.start_with?("#{id}/")
          sink
        end
      end

      def normalise_type(types, tabs = '')
        types = [types] unless types.is_a?(Array)
        types.map do |type|
          t = type.is_a?(String) ? { 'type' => type } : type.dup

          if t.key?('items')
            t['items'] = normalise_type(t['items'], tabs + ' ')
          end

          if t.key?('fields')
            f = []
            if t['fields'].is_a?(Hash)
              t['fields'].each do |name, value|
                f << (value.is_a?(String) ? { 'type' => value } : value).merge('name' => name)
              end
            end
            t['fields'] = f.map { |fi| normalise_type(fi['type'], tabs + ' ') }
          end

          t
        end
      end
    end
  end
end
