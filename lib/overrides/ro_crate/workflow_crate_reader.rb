require 'ro_crate'

module ROCrate
  class WorkflowCrateReader < ::ROCrate::Reader
    def self.build_crate(entity_hash, source, crate_class: ROCrate::WorkflowCrate, context:)
      super(entity_hash, source, crate_class: crate_class, context: context)
    end

    def self.extract_data_entities(crate, source, entity_hash)
      main_wf = entity_hash.delete(crate.properties.dig('mainEntity', '@id'))
      if main_wf && (['ComputationalWorkflow', 'Workflow'] & Array(main_wf['@type'])).any?
        crate.main_workflow = create_data_entity(crate, ROCrate::Workflow, source, main_wf)
        diagram = entity_hash.delete(main_wf.dig('image', '@id'))
        if diagram
          crate.main_workflow.diagram = create_data_entity(crate, ROCrate::WorkflowDiagram, source, diagram)
        end
        cwl = entity_hash.delete(main_wf.dig('subjectOf', '@id'))
        if cwl
          crate.main_workflow.cwl_description = create_data_entity(crate, ROCrate::WorkflowDescription, source, cwl)
        end
      else
        Rails.logger.warn 'Main workflow not found!'
      end

      super
    end
  end
end
