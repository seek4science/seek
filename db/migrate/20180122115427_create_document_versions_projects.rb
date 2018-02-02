class CreateDocumentVersionsProjects < ActiveRecord::Migration
  def change
    create_table :document_versions_projects do |t|
      t.references :version, references: :documents
      t.references :project
    end

    add_index :document_versions_projects, [:version_id, :project_id],
              name: 'index_document_versions_projects_on_version_id_and_project_id' # Need to name manually because rails makes it too long (> 64 chars)
    add_index :document_versions_projects, [:project_id]
  end
end
