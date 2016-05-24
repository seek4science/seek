class CreateSampleAttributeTypes < ActiveRecord::Migration
  def change
    create_table :sample_attribute_types do |t|
      t.string :title
      t.string :base_type
      t.string :regexp

      t.timestamps
    end
  end
end
