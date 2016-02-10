class SampleAttribute < ActiveRecord::Base
  attr_accessible :sample_attribute_type_id, :title, :required, :sample_attribute_type

  belongs_to :sample_attribute_type

  validates :title,:sample_attribute_type, presence:true

  def validate_value?(value)
    return false if required? && value.blank?
    (value.blank? && !required?) || sample_attribute_type.validate_value?(value)
  end

end
