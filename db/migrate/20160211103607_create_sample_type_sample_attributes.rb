class CreateSampleTypeSampleAttributes < ActiveRecord::Migration
  def change
    create_table :sample_type_sample_attributes, :id=>false do |t|
      t.integer :sample_type_id
      t.integer :sample_attribute_id
      t.integer :pos
    end
    add_index :sample_type_sample_attributes, [:sample_type_id, :pos]
    add_index :sample_type_sample_attributes, [:sample_type_id]
  end
end
