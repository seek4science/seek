# This extends the AnnotationAttribute model defined in the Annotations plugin.

require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'models', 'text_value')

class TextValue < ActiveRecord::Base

  def self.all_tags attributes=["tag","expertise","tool"]
    attributes = [attributes] if attributes.is_a?(String)
    attributes.reduce([]){|tags,attr| tags | Annotation.with_attribute_name(attr).collect{|ann| ann.value}}.uniq
  end

  def annotation_count attributes
    attributes = [attributes] if attributes.is_a?(String)
    attributes.reduce(0) do |sum,attr|
      sum + annotations.with_attribute_name(attr).count
    end
  end

  def tag_count
    annotation_count ["tag","expertise","tool"]
  end
  
end