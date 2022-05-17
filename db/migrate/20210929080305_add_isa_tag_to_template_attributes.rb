class AddIsaTagToTemplateAttributes < ActiveRecord::Migration[5.2]
  def change
    add_column :template_attributes, :isa_tag_id, :integer
  end
end
