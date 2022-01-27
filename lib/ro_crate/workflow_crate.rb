require 'ro_crate'

module ROCrate
  class WorkflowCrate < ::ROCrate::Crate
    PROFILE = {
      '@id' => 'https://about.workflowhub.eu/Workflow-RO-Crate/',
      '@type' => 'CreativeWork',
      'name' => 'Workflow RO-Crate Profile',
      'version' => '0.2.0'
    }.freeze

    include ActiveModel::Model

    validates :main_workflow, presence: true

    properties(%w[mainEntity mentions about])

    def initialize(*args)
      super.tap do
        prof = add_contextual_entity(ROCrate::ContextualEntity.new(self, nil, PROFILE))
        conforms = metadata['conformsTo']
        if conforms.is_a?(Array)
          metadata['conformsTo'] << prof.reference
        else
          metadata['conformsTo'] = [{ '@id' => ::ROCrate::Metadata::SPEC }, prof.reference]
        end
      end
    end

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

    def test_suites
      ((mentions || []) | (about || [])).select { |entity| entity.has_type?('TestSuite') }
    end

    def readme
      dereference('README.md')
    end

    def find_entry(path)
      entries[path]
    end
  end
end
