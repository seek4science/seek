require 'ro_crate_ruby'

module ROCrate
  class WorkflowDiagram < ::ROCrate::File
    def default_properties
      super.merge(
          '@id' => "./#{SecureRandom.uuid}",
          '@type' => ['File', 'ImageObject', 'WorkflowSketch']
      )
    end
  end
end
