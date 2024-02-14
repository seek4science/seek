require 'ro_crate'

module RoCrate
  class Workflow < ::ROCrate::File
    properties(%w[image subjectOf programmingLanguage license])

    def diagram
      image
    end

    def diagram=(entity)
      crate.add_data_entity(entity).tap do |entity|
        self.image = entity
      end
    end

    def cwl_description
      subject_of
    end

    def cwl_description=(entity)
      crate.add_data_entity(entity).tap do |entity|
        self.subject_of = entity
      end
    end

    def default_properties
      super.merge('@type' => ['File', 'SoftwareSourceCode', 'ComputationalWorkflow'])
    end
  end
end
