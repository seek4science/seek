module RoCrate
  class WorkflowDescription < ::ROCrate::File
    properties(%w[image subjectOf programmingLanguage license])

    def initialize(*args)
      super.tap do
        cwl = ROCrate::ContextualEntity.new(self.crate, nil, Seek::WorkflowExtractors::Cwl::ABSTRACT_CWL_METADATA)
        self.programming_language = self.crate.add_contextual_entity(cwl)
      end
    end

    def default_properties
      super.merge('@type' => ['File', 'SoftwareSourceCode', 'HowTo'])
    end
  end
end
