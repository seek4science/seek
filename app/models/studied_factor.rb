class StudiedFactor < ActiveRecord::Base

  belongs_to :sop
  belongs_to :factor_type
  belongs_to :measured_item
  belongs_to :unit
  belongs_to :study
  
end
