class SampleTypeSampleAttribute < ActiveRecord::Base
  attr_accessible :pos, :sample_attribute, :sample_type, :sample_type_id

  before_save :default_pos

  belongs_to :sample_type
  belongs_to :sample_attribute

  private

  # if not set, takes the next value for that sample type
  def default_pos
    self.pos ||= (SampleTypeSampleAttribute.where(sample_type_id: sample_type_id).maximum(:pos) || 0) + 1
  end
end
