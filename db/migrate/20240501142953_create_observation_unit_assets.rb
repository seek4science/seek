class CreateObservationUnitAssets < ActiveRecord::Migration[6.1]
  def change
    create_table :observation_unit_assets, id: false do |t|
      t.references :observation_unit
      t.references :asset, polymorphic: true
    end
  end
end
