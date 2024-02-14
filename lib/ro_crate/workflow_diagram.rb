require 'ro_crate'

module RoCrate
  class WorkflowDiagram < ::ROCrate::File
    def default_properties
      super.merge('@type' => ['File', 'ImageObject', 'WorkflowSketch'])
    end
  end
end
