class ObservationUnitAsset < ApplicationRecord

  belongs_to :observation_unit, inverse_of: :observation_unit_assets
  belongs_to :asset, polymorphic: true, inverse_of: :observation_unit_assets

end
