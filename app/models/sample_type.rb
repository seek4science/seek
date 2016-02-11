class SampleType < ActiveRecord::Base
  attr_accessible :title, :uuid

  acts_as_uniquely_identifiable

  has_many :samples

  has_many :sample_attributes, through: :sample_type_sample_attributes, order: :pos
  has_many :sample_type_sample_attributes, order: :pos

  validates :title, presence: true

  def add_attribute(attribute, position)
    sample_type_sample_attributes << SampleTypeSampleAttribute.new(sample_attribute: attribute, pos: position)
  end
end
