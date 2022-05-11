class AddIsTitleToTemplateAttributes < ActiveRecord::Migration[5.2]
  def change
    add_column :template_attributes,:is_title,:boolean,:default=>false
  end
end
