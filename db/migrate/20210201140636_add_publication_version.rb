class AddPublicationVersion < ActiveRecord::Migration[5.2]
  def change
    create_table "publication_versions", force: :cascade do |t|
      t.integer  "publication_id",              limit: 4
      t.integer  "version",             limit: 4
      t.text     "revision_comments",   limit: 65535
      t.integer  "contributor_id",      limit: 4
      t.string   "title",               limit: 255
      t.text     "description",         limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "last_used_at"
      t.string   "first_letter",        limit: 1
      t.text     "other_creators",      limit: 65535
      t.string   "uuid",                limit: 255
      t.integer  "policy_id",           limit: 4
      t.string   "doi",                 limit: 255
      t.string   "license",             limit: 255
      t.string   "deleted_contributor", limit: 255
    end

    add_index "publication_versions", ["contributor_id"], name: "index_publication_versions_on_contributor", using: :btree
    add_index "publication_versions", ["publication_id"], name: "index_publication_versions_on_publication_id", using: :btree

    add_column :publications,:version, :integer,             limit: 4,     default: 1
  end
end
