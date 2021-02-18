class AddPublicationVersionProject < ActiveRecord::Migration[5.2]
  def change
    create_table "projects_publication_versions", id: false, force: :cascade do |t|
      t.integer "project_id", limit: 4
      t.integer "publication_id", limit: 4
    end

    create_table "projects_publication", id: false, force: :cascade do |t|
      t.integer "project_id", limit: 4
      t.integer "publication_id",     limit: 4
    end
  end
end
