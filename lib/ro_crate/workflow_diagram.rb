require 'ro_crate_ruby'

module ROCrate
  class WorkflowDiagram < ::ROCrate::File
    def default_properties
      super.merge('@type' => ['File', 'ImageObject', 'WorkflowSketch'])
    end
  end
end
