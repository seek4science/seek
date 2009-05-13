class Culture < ActiveRecord::Base

  has_one :organism
  belongs_to :sop

end
