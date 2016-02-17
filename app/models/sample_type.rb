class SampleType < ActiveRecord::Base
  attr_accessible :title, :uuid, :sample_attributes_attributes

  acts_as_uniquely_identifiable

  has_many :samples

  has_many :sample_attributes, order: :pos

  validates :title, presence: true

  accepts_nested_attributes_for :sample_attributes

  def validate_value?(attribute_name, value)
    attribute = sample_attributes.detect { |attr| attr.title == attribute_name }
    fail UnknownAttributeException.new("Unknown attribute #{attribute_name}") if attribute.nil?
    attribute.validate_value?(value)
  end

  private

  class UnknownAttributeException < Exception; end

end
