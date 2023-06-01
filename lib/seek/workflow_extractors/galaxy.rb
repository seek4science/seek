require 'open4'

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
        err = ''
        status = Open4.popen4(Seek::Util.python_exec("-m gxformat2.abstract #{f.path} #{cf.path}")) do |_pid, _stdin, _stdout, stderr|
          err = stderr.read.strip
          stderr.close
        end
        cf.rewind
        if status.success?
          metadata = Seek::WorkflowExtractors::CWL.new(cf).metadata
        else
          metadata = super
          metadata[:warnings] ||= []
          metadata[:warnings] << 'Unable to convert workflow to CWL, some metadata may be missing.'
          Rails.logger.error("Galaxy -> CWL conversion failed. Error was: #{err}")
        end
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
          people, others = Array(galaxy['creator']).partition { |c| c['class'] == 'Person' }
          people.each_with_index do |c, i|
            author = extract_author(c)
            unless author.blank?
              metadata[:assets_creators_attributes] ||= {}
              metadata[:assets_creators_attributes][i.to_s] = author.merge(pos: i)
            end
          end
          other_creators = others.map { |c| c['name'] }.reject(&:blank?)
          metadata[:other_creators] = other_creators.join(', ') if other_creators.any?
        end

        metadata[:internals] ||= {}
        metadata[:internals][:steps] = []
        tool_ids = []
        galaxy['steps'].each do |num, step|
          tool_id = step['tool_id']
          if tool_id.present?
            tool_id = tool_id.to_s
            tool_ids << tool_id
          end
          unless ['data_input', 'data_collection_input', 'parameter_input'].include?(step['type'])
            metadata[:internals][:steps] << { id: step['id'].to_s,
                                              name: step['label'] || step['name'],
                                              description: [step['annotation'], tool_id].reject(&:blank?).map(&:to_s).join("\n") }
          end
        end

        # Copy ID to name field, if not present
        [metadata[:internals][:inputs] || [], metadata[:internals][:outputs] || []].each do |port_type|
          port_type.each do |port|
            port[:name] ||= port[:id]
          end
        end

        # Exclude inputs from workflow outputs
        if metadata[:internals][:outputs]
          metadata[:internals][:outputs].reject! do |output|
            output[:id].sub('#main/', '').start_with?('_anonymous_output_') &&
              (output[:source_ids] || []).length == 1 &&
              metadata[:internals][:inputs].detect { |i| i[:id] == output[:source_ids].first }
          end
        end

        metadata[:tags] = galaxy['tags']

        tools = tool_ids.uniq.map { |i| ::Galaxy::ToolMap.instance.lookup(i, strip_version: true) }.compact.uniq
        metadata[:tools_attributes] = tools if tools.any?

        metadata
      end
    end
  end
end
