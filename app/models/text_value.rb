# Imported from the my_annotations plugin developed as part of BioCatalogue and no longer maintained. Originally found at https://github.com/myGrid/annotations

class TextValue < ApplicationRecord
  include AnnotationsVersionFu
  include TextValueExtensions

  validates_presence_of :text

  acts_as_annotation_value :content_field => :text

  belongs_to :version_creator,
             :class_name => "::#{Annotations::Config.user_model_name}"

  # ========================
  # Versioning configuration
  # ------------------------

  annotations_version_fu do
    validates_presence_of :text

    belongs_to :version_creator,
               :class_name => "::#{Annotations::Config.user_model_name}"
  end

  # ========================
end
