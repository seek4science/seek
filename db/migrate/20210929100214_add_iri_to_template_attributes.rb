class AddIriToTemplateAttributes < ActiveRecord::Migration[5.2]
  def change
    add_column :template_attributes,:iri, :string
  end
end
