class WorkflowClass < ApplicationRecord
  def extractor_class
    class_name = "Seek::WorkflowExtractors::#{key}"
    if const_defined?(class_name)
      self.class.const_get(class_name)
    else
      Seek::WorkflowExtractors::Base
    end
  end

  def self.extractor_class_for(id)
    (find_by_id(id)&.extractor_class || Seek::WorkflowExtractors::Base)
  end

  def self.extractor_for(id, content_blob)
    extractor_class_for(id).new(content_blob)
  end
end
