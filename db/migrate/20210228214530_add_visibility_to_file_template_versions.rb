class AddVisibilityToFileTemplateVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :file_template_versions, :visibility, :integer
  end
end
