class SampleType < ActiveRecord::Base
  attr_accessible :title, :uuid

  acts_as_uniquely_identifiable

  has_many :samples

  has_many :sample_attributes, order: :pos

  validates :title, presence: true

  def add_attribute(attribute, position)
    sample_type_sample_attributes << SampleAttribute.new(attribute.merge(pos: position))
  end

  def validate_value?(attribute_name, value)
    attribute = sample_attributes.detect { |attr| attr.title == attribute_name }
    fail UnknownAttributeException.new("Unknown attribute #{attribute_name}") if attribute.nil?
    attribute.validate_value?(value)
  end

  private

  class UnknownAttributeException < Exception; end

end
