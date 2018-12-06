class AddNodes < ActiveRecord::Migration[4.2]
  def change
    create_table "node_versions_projects", id: false, force: :cascade do |t|
      t.integer "project_id", limit: 4
      t.integer "version_id", limit: 4
    end

    create_table "nodes_projects", id: false, force: :cascade do |t|
      t.integer "project_id", limit: 4
      t.integer "node_id",     limit: 4
    end

    create_table "node_auth_lookup", id: false, force: :cascade do |t|
      t.integer "user_id",      limit: 4
      t.integer "asset_id",     limit: 4
      t.boolean "can_view",               default: false
      t.boolean "can_manage",             default: false
      t.boolean "can_edit",               default: false
      t.boolean "can_download",           default: false
      t.boolean "can_delete",             default: false
    end

    add_index "node_auth_lookup", ["user_id", "asset_id", "can_view"], name: "index_n_auth_lookup_on_user_id_and_asset_id_and_can_view", using: :btree
    add_index "node_auth_lookup", ["user_id", "can_view"], name: "index_n_auth_lookup_on_user_id_and_can_view", using: :btree

    create_table "node_versions", force: :cascade do |t|
      t.integer  "node_id",              limit: 4
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

    add_index "node_versions", ["contributor_id"], name: "index_node_versions_on_contributor", using: :btree
    add_index "node_versions", ["node_id"], name: "index_node_versions_on_node_id", using: :btree

    create_table "nodes", force: :cascade do |t|
      t.integer  "contributor_id",      limit: 4
      t.string   "title",               limit: 255
      t.text     "description",         limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "last_used_at"
      t.integer  "version",             limit: 4,     default: 1
      t.string   "first_letter",        limit: 1
      t.text     "other_creators",      limit: 65535
      t.string   "uuid",                limit: 255
      t.integer  "policy_id",           limit: 4
      t.string   "doi",                 limit: 255
      t.string   "license",             limit: 255
      t.string   "deleted_contributor", limit: 255
    end

    add_index "nodes", ["contributor_id"], name: "index_nodes_on_contributor", using: :btree


  end
end
