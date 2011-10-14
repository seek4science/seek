class TextValue < ActiveRecord::Base
  include AnnotationsVersionFu
  
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
