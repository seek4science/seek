# This extends the AnnotationAttribute model defined in the Annotations plugin.

require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'models', 'text_value')

class TextValue < ActiveRecord::Base

  def self.all_tags
    annotations = Annotation.with_attribute_name("tag") | Annotation.with_attribute_name("expertise") | Annotation.with_attribute_name("tool")
    annotations.collect{|a| a.value}.uniq
  end
end