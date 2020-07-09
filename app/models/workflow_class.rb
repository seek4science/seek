class WorkflowClass < ApplicationRecord
  def extractor_class
    class_name = "Seek::WorkflowExtractors::#{key}"
    begin
      self.class.const_get(class_name)
    rescue NameError
      Seek::WorkflowExtractors::Base
    end
  end
end
