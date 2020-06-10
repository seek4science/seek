class CreateCollectionsProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :collections_projects do |t|
      t.references :collection
      t.references :project, index: true
    end

    add_index :collections_projects, [:collection_id, :project_id]
  end
end
