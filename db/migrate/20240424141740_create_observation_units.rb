class CreateObservationUnits < ActiveRecord::Migration[6.1]
  def change
    create_table :observation_units do |t|
      t.string :title
      t.text :description
      t.string :identifier
      t.bigint :organism_id
      t.bigint :extended_metadata_type_id

      t.timestamps
    end
  end
end
