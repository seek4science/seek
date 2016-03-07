class SampleType < ActiveRecord::Base
  attr_accessible :title, :uuid, :sample_attributes_attributes

  acts_as_uniquely_identifiable

  has_many :samples

  has_many :sample_attributes, order: :pos, inverse_of: :sample_type

  validates :title, presence: true
  validate :one_title_attribute_present

  accepts_nested_attributes_for :sample_attributes, allow_destroy: true

  def validate_value?(attribute_name, value)
    attribute = sample_attributes.detect { |attr| attr.title == attribute_name }
    fail UnknownAttributeException.new("Unknown attribute #{attribute_name}") if attribute.nil?
    attribute.validate_value?(value)
  end

  private

  def one_title_attribute_present
    unless (count = sample_attributes.select(&:is_title).count) == 1
      errors.add(:sample_attributes, "There must be 1 attribute which is the title, currently there are #{count}")
    end
  end

  class UnknownAttributeException < Exception; end
end
