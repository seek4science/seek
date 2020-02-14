require 'ro_crate_ruby'

module ROCrate
  class WorkflowCrate < ::ROCrate::Crate
    properties(%w[mainEntity])

    def main_workflow
      main_entity
    end

    def main_workflow=(entity)
      add_data_entity(entity).tap do |entity|
        self.main_entity = entity
      end
    end

    def main_workflow_diagram
      main_workflow&.properties&.[]('image')&.dereference
    end

    def main_workflow_diagram=(entity)
      raise "No main workflow!" if main_workflow.nil?

      main_workflow.diagram = entity
    end

    def main_workflow_cwl
      main_workflow&.properties&.[]('subjectOf')&.dereference
    end

    def main_workflow_cwl=(entity)
      raise "No main workflow!" if main_workflow.nil?

      main_workflow.cwl_description = entity
    end
  end
end
