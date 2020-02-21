require 'ro_crate_ruby'

module ROCrate
  class WorkflowCrate < ::ROCrate::Crate
    include ActiveModel::Model

    validates :main_workflow, presence: true

    properties(%w[mainEntity])

    def main_workflow
      main_entity
    end

    def main_workflow=(entity)
      add_data_entity(entity).tap { |entity| self.main_entity = entity }
    end

    def main_workflow_diagram
      main_workflow&.image
    end

    def main_workflow_diagram=(entity)
      raise "No main workflow!" if main_workflow.nil?

      main_workflow.diagram = entity
    end

    def main_workflow_cwl
      main_workflow&.subject_of
    end

    def main_workflow_cwl=(entity)
      raise "No main workflow!" if main_workflow.nil?

      main_workflow.cwl_description = entity
    end
  end
end
