require 'ro_crate_ruby'

module ROCrate
  class WorkflowCrateReader < ::ROCrate::Reader
    def self.build_crate(entity_hash, source)
      ROCrate::WorkflowCrate.new.tap do |crate|
        crate.properties = entity_hash.delete(ROCrate::Crate::IDENTIFIER)
        crate.metadata.properties = entity_hash.delete(ROCrate::Metadata::IDENTIFIER)
        main_wf = entity_hash.delete(crate.properties.dig('mainEntity', '@id'))
        if main_wf
          crate.main_workflow = ROCrate::Workflow.new(crate, ::File.join(source, main_wf['@id']), main_wf['@id'], main_wf)
          diagram = entity_hash.delete(main_wf.dig('image', '@id'))
          if diagram
            crate.main_workflow.diagram = ROCrate::WorkflowDiagram.new(crate, ::File.join(source, diagram['@id']), diagram['@id'], diagram)
          end
          cwl = entity_hash.delete(main_wf.dig('subjectOf', '@id'))
          if cwl
            crate.main_workflow.cwl_description = ROCrate::WorkflowDescription.new(crate, ::File.join(source, cwl['@id']), cwl['@id'], cwl)
          end
        else
          warn 'Main workflow not found!'
        end

        extract_data_entities(crate, source, entity_hash).each do |entity|
          crate.add_data_entity(entity)
        end

        # The remaining entities in the hash must be contextual.
        extract_contextual_entities(crate, entity_hash).each do |entity|
          crate.add_contextual_entity(entity)
        end
      end
    end
  end
end
