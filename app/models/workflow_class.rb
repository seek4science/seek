class WorkflowClass < ApplicationRecord
  def extractor_class
    self.class.const_get("Seek::WorkflowExtractors::#{key}")
  end
end
