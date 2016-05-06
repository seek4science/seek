class CreateSampleAttributes < ActiveRecord::Migration
  def change
    create_table :sample_attributes do |t|
      t.string :title
      t.integer :sample_attribute_type_id
      t.boolean :required, :default=>false

      t.timestamps
    end
  end
end
