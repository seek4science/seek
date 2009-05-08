class StudiedFactor < ActiveRecord::Base

  belongs_to :sop
  belongs_to :condition_type
  belongs_to :measured_item
  belongs_to :unit
  
end
