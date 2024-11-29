class AddParentAttributeIdToTemplateAttributes < ActiveRecord::Migration[6.1]
  def change
    add_column :template_attributes, :parent_attribute_id, :integer
    add_index :template_attributes, :parent_attribute_id
  end
end
