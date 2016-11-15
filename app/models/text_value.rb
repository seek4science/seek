# This extends the AnnotationAttribute model defined in the Annotations gem.

require_dependency File.join(Gem.loaded_specs['my_annotations'].full_gem_path,'lib','app','models','text_value')

class TextValue < ActiveRecord::Base

  TAG_TYPES=["tag","expertise","tool","sample_type_tags"]

  def self.all_tags attributes=TAG_TYPES
    self.with_attribute_names(attributes).compact
  end

  def tag_count
    annotation_count TAG_TYPES
  end
  
end