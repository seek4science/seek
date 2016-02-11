class SampleTypeSampleAttribute < ActiveRecord::Base
  attr_accessible :pos, :sample_attribute, :sample_type_id

  belongs_to :sample_type
  belongs_to :sample_attribute
end
