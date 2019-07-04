# Imported from the my_annotations plugin developed as part of BioCatalogue and no longer maintained. Originally found at https://github.com/myGrid/annotations

class AnnotationValueSeed < ApplicationRecord
  validates_presence_of :attribute_id,
                        :value_type,
                        :value_id

  belongs_to :value,
             polymorphic: true

  belongs_to :annotation_attribute,
             class_name: 'AnnotationAttribute',
             foreign_key: 'attribute_id'

  # Named scope to allow you to include the value records too.
  # Use this to *potentially* improve performance.
  scope :include_values, lambda {
    includes([:value])
  }

  # Finder to get all annotation value seeds with a given attrib_name.
  scope :with_attribute_name, lambda { |attrib_name|
    where(annotation_attributes: { name: attrib_name })
      .joins(:annotation_attribute)
      .order('created_at DESC')
  }

  # Finder to get all annotation value seeds with one of the given attrib_names.
  scope :with_attribute_names, lambda { |attrib_names|
    conditions = [attrib_names.collect { 'annotation_attributes.name = ?' }.join(' or ')] | attrib_names
    where(conditions)
      .joins(:annotation_attribute)
      .order('created_at DESC')
  }

  # Finder to get all annotations for a given value_type.
  scope :with_value_type, lambda { |value_type|
    where(value_type: value_type)
      .order('created_at DESC')
  }

  def self.find_by_attribute_name(attr_name)
    return [] if attr_name.blank?

    AnnotationValueSeed.joins(:annotation_attribute)
                       .where(annotation_attributes: { name: attr_name })
                       .order('created_at DESC')
  end
end
