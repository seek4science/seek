class AddResolutionToSampleAttributeTypes < ActiveRecord::Migration
  def change
    add_column :sample_attribute_types, :resolution, :string
  end
end
