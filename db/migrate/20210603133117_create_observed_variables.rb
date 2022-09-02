class CreateObservedVariables < ActiveRecord::Migration[5.2]
  def change
    create_table :observed_variables do |t|
      t.integer :observed_variable_set_id
      t.string :variable_id
      t.string :variable_name
      t.string :variable_an
      t.string :trait
      t.string :trait_an
      t.string :trait_entity
      t.string :trait_entity_an
      t.string :trait_attribute
      t.string :trait_attribute_an
      t.string :method
      t.string :method_an
      t.text :method_description
      t.string :method_reference
      t.string :scale
      t.string :scale_an
      t.string :timescale

      t.timestamps
    end
  end
end
