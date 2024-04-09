require 'ro_crate'

module ROCrate
  class WorkflowCrate < ::ROCrate::Crate
    PROFILE_REF = { '@id' => 'https://w3id.org/workflowhub/workflow-ro-crate/1.0' }.freeze

    include ActiveModel::Model

    validates :main_workflow, presence: true

    properties(%w[mainEntity mentions about])

    def initialize(*args)
      super.tap do
        conforms = self['conformsTo']
        if conforms.is_a?(Array)
          self['conformsTo'] << PROFILE_REF
        else
          self['conformsTo'] = [{ '@id' => ::ROCrate::Metadata::SPEC }, PROFILE_REF]
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

    def find_entry(path)
      entries[path]
    end

    def source_url
      url = id if id.start_with?('http')
      url || self['isBasedOn'] || self['url'] || self.main_workflow['url']
    end
  end
end
