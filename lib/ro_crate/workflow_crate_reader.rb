require 'ro_crate_ruby'

module ROCrate
  class WorkflowCrateReader < ::ROCrate::Reader
    def self.initialize_crate(entities)
      ROCrate::WorkflowCrate.new.tap do |crate|
        crate.properties = entities[ROCrate::Crate::IDENTIFIER]
        crate.metadata.properties = entities[ROCrate::Metadata::IDENTIFIER]
        # Main Workflow
        main_wf = entities.delete(entities[ROCrate::Crate::IDENTIFIER].dig('mainEntity', '@id'))
        if main_wf
          crate.main_workflow = ROCrate::Workflow.new(crate, yield(main_wf['@id']), main_wf['@id'], main_wf)
          diagram = entities.delete(main_wf.dig('image', '@id'))
          if diagram
            crate.main_workflow.diagram = ROCrate::WorkflowDiagram.new(crate, yield(diagram['@id']), diagram['@id'], diagram)
          end
          cwl = entities.delete(main_wf.dig('subjectOf', '@id'))
          if cwl
            crate.main_workflow.cwl_description = ROCrate::WorkflowDescription.new(crate, yield(cwl['@id']), cwl['@id'], cwl)
          end
        else
          warn 'Main workflow not found!'
        end

        entities[ROCrate::Crate::IDENTIFIER]['hasPart'].each do |ref|
          part = entities.delete(ref['@id'])
          next unless part
          if Array(part['@type']).include?('Dataset')
            thing = ROCrate::Directory.new(crate, nil, nil, part)
          else
            file = yield(part['@id'])
            if file
              thing = ROCrate::File.new(crate, file, part['@id'], part)
            else
              warn "Could not find: #{part['@id']}"
            end
          end
          crate.add_data_entity(thing)
        end

        entities.each do |id, entity|
          crate.create_contextual_entity(id, entity)
        end
      end
    end
  end
end
