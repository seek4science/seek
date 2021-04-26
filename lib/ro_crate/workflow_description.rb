module ROCrate
  class WorkflowDescription < ::ROCrate::File
    properties(%w[image subjectOf programmingLanguage license])

    def initialize(*args)
      super.tap do
        self.programming_language = self.crate.add_contextual_entity(ROCrate::ContextualEntity.new(self.crate, nil, Seek::WorkflowExtractors::CWL.ro_crate_metadata))
      end
    end

    def default_properties
      super.merge('@type' => ['File', 'SoftwareSourceCode', 'HowTo'])
    end
  end
end
