class CreateObservationUnits < ActiveRecord::Migration[6.1]
  def change
    create_table :observation_units do |t|
      t.string :title
      t.string :description
      t.string :text
      t.string :identifier
      t.string :string
      t.string :organism_id
      t.string :extended_metadata_type_id
      t.string :integer

      t.timestamps
    end
  end
end
