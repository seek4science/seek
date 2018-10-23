module TextValueExtensions
  extend ActiveSupport::Concern

  TAG_TYPES=["tag","expertise","tool","sample_type_tags"]

  class_methods do
    def all_tags attributes=TAG_TYPES
      self.with_attribute_names(attributes).compact
    end
  end

  def tag_count
    annotation_count TAG_TYPES
  end

  def create_new_version?
    false
  end
end

TextValue.class_eval do
  include TextValueExtensions
end
