class CreateOtherProjectFilesProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :other_project_files_projects, :id => false do |t|
      t.integer :project_id
      t.integer :other_project_file_id
    end
    add_index :other_project_files_projects, [:project_id, :other_project_file_id], name: 'index_project_id_other_project_file_id'
  end
end
