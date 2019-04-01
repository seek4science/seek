# Imported from the my_annotations plugin developed as part of BioCatalogue and no longer maintained. Originally found at https://github.com/myGrid/annotations

class TextValue < ApplicationRecord

  TAG_TYPES = %w[tag expertise tool sample_type_tags].freeze

  validates_presence_of :text

  acts_as_annotation_value content_field: :text

  belongs_to :version_creator,
             class_name: "::#{Annotations::Config.user_model_name}"

  def self.all_tags(attributes = TAG_TYPES)
    with_attribute_names(attributes).compact
  end

  def tag_count
    annotation_count TAG_TYPES
  end

  def create_new_version?
    false
  end

end
