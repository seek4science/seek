module Seek
  module WorkflowExtractors
    class Galaxy < Base
      def self.file_extensions
        ['ga']
      end

      def metadata
        galaxy_string = @io.read
        f = Tempfile.new('ga')
        f.binmode
        f.write(galaxy_string)
        f.rewind
        cf = Tempfile.new('cwl')
        `gxwf-abstract-export #{f.path} #{cf.path}`
        cf.rewind
        metadata = Seek::WorkflowExtractors::CWL.new(cf).metadata
        galaxy = JSON.parse(galaxy_string)

        if galaxy.has_key?('name')
          metadata[:title] = galaxy['name']
        else
          metadata[:warnings] ||= []
          metadata[:warnings] << 'Unable to determine title of workflow'
        end

        metadata[:description] = galaxy['annotation'] if galaxy['annotation'].present?
        metadata[:license] = galaxy['license'] if galaxy['license'].present?

        if galaxy['creator']
          creators = Array(galaxy['creator']).select { |c| c['class'] == 'Person' }.map { |c| c['name'] }
          metadata[:other_creators] = creators.join(', ') if creators.any?
        end

        metadata[:internals][:steps] = []
        galaxy['steps'].each do |num, step|
          unless ['data_input', 'data_collection_input', 'parameter_input'].include?(step['type'])
            metadata[:internals][:steps] << { id: step['id'].to_s, name: step['label'] || step['name'], description: (step['annotation'] || '') + "\n " + (step['tool_id'] || '') }
          end
        end

        # Copy ID to name field, if not present
        [metadata[:internals][:inputs] || [], metadata[:internals][:outputs] || []].each do |port_type|
          port_type.each do |port|
            port[:name] ||= port[:id]
          end
        end

        metadata[:tags] = galaxy['tags']

        metadata
      end
    end
  end
end
