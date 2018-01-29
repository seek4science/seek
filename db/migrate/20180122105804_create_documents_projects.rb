class CreateDocumentsProjects < ActiveRecord::Migration
  def change
    create_table :documents_projects do |t|
      t.references :document
      t.references :project
    end

    add_index :documents_projects, [:document_id, :project_id]
    add_index :documents_projects, [:project_id]
  end
end
