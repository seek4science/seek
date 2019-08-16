class Culture < ApplicationRecord

  has_one :organism
  belongs_to :sop

end
