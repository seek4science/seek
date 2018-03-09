class AddDescriptionToSampleAttributeTypes < ActiveRecord::Migration
  def change
    add_column :sample_attribute_types, :description, :text
  end
end
