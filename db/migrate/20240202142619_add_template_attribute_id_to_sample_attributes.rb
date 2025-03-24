class AddTemplateAttributeIdToSampleAttributes < ActiveRecord::Migration[6.1]
  def change
    add_column :sample_attributes, :template_attribute_id, :integer
    add_index :sample_attributes, :template_attribute_id
  end
end
