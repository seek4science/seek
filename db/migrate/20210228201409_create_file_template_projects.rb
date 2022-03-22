class CreateFileTemplateProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :file_templates_projects, force: :cascade do |t|
      t.references :file_template
      t.references :project
    end

    add_index :file_templates_projects, [:file_template_id, :project_id]
#    add_index :file_templates_projects, [:project_id]
  end
end
