class ObservationUnitAsset < ApplicationRecord

  belongs_to :observation_unit
  belongs_to :asset, polymorphic: true

end
