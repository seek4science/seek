class AddFullPublicationVersion < ActiveRecord::Migration[5.2]
  def change
    create_table "publication_versions", force: :cascade do |t|
      t.integer  "publication_id"
      t.integer  "version"
      t.text     "revision_comments"
      t.integer "pubmed_id"
      t.text "title"
      t.text "abstract"
      t.date "published_date"
      t.string "journal"
      t.string "first_letter", limit: 1
      t.integer "contributor_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "last_used_at"
      t.string "doi"
      t.string "uuid"
      t.integer "policy_id"
      t.text "citation"
      t.string "deleted_contributor"
      t.integer "registered_mode"
      t.text "booktitle"
      t.string "publisher"
      t.text "editor"
      t.integer "publication_type_id"
      t.text "url"
    end

    add_index "publication_versions", ["contributor_id"], name: "index_publication_versions_on_contributor", using: :btree
    add_index "publication_versions", ["publication_id"], name: "index_publication_versions_on_publication_id", using: :btree

    create_table "projects_publication_versions", id: false, force: :cascade do |t|
      t.integer "project_id"
      t.integer "publication_id"
    end
  end
end
