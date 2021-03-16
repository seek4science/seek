class CreatePlaceholderProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :placeholders_projects do |t|
      t.references :placeholder
      t.references :project
    end

    add_index :placeholders_projects, [:placeholder_id, :project_id]
  end
end
