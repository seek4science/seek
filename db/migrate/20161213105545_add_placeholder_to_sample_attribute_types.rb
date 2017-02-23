class AddPlaceholderToSampleAttributeTypes < ActiveRecord::Migration

  def change
    add_column :sample_attribute_types, :placeholder, :string
  end

end
