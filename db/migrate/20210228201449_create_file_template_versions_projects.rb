class CreateFileTemplateVersionsProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :file_template_versions_projects, force: :cascade do |t|
      t.references :version, references: :file_templates
      t.references :project
    end

    add_index :file_template_versions_projects, [:version_id, :project_id],
              name: 'index_ft_versions_projects_on_version_id_and_project_id'
#    add_index :file_template_versions_projects, [:project_id]
  end
end
