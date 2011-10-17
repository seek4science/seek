class AnnotationValueSeed < ActiveRecord::Base
  validates_presence_of :attribute_id,
                        :value_type,
                        :value_id
  
  belongs_to :value,
             :polymorphic => true
             
  belongs_to :attribute,
             :class_name => "AnnotationAttribute",
             :foreign_key => "attribute_id"

  # Named scope to allow you to include the value records too.
  # Use this to *potentially* improve performance.
  named_scope :include_values, lambda {
    { :include => [ :value ] }
  }

  # Finder to get all annotation value seeds with a given attrib_name.
  named_scope :with_attribute_name, lambda { |attrib_name|
    { :conditions => { :annotation_attributes => { :name => attrib_name } },
      :joins => :attribute,
      :order => "created_at DESC" }
  }

  # Finder to get all annotation value seeds with one of the given attrib_names.
  named_scope :with_attribute_names, lambda { |attrib_names|
    conditions = [attrib_names.collect{"annotation_attributes.name = ?"}.join(" or ")] | attrib_names
    { :conditions => conditions,
      :joins => :attribute,
      :order => "created_at DESC" }
  }

  # Finder to get all annotations for a given value_type.
  named_scope :with_value_type, lambda { |value_type|
    { :conditions => { :value_type =>  value_type },
      :order => "created_at DESC" }
  }
  
  def self.find_by_attribute_name(attr_name)
    return [] if attr_name.blank?
          
    AnnotationValueSeed.find(:all,
                             :joins => [ :attribute ],
                             :conditions => { :annotation_attributes => { :name => attr_name } },
                             :order => "created_at DESC")
  end
end