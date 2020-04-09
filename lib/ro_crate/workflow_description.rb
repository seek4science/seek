module ROCrate
  class WorkflowDescription < ::ROCrate::Workflow
    properties(%w[programmingLanguage])

    def initialize(*args)
      super.tap do
        self.programming_language = self.crate.add_contextual_entity(ROCrate::ContextualEntity.new(self.crate, nil, Seek::WorkflowExtractors::CWL.ro_crate_metadata))
      end
    end
  end
end
