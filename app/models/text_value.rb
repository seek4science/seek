# This extends the AnnotationAttribute model defined in the Annotations gem.

require_dependency File.join(Gem.loaded_specs['my_annotations'].full_gem_path,'lib','app','models','text_value')

class TextValue < ActiveRecord::Base

  def self.all_tags attributes=["tag","expertise","tool"]
    self.with_attribute_names attributes
  end

  def tag_count
    annotation_count ["tag","expertise","tool"]
  end
  
end