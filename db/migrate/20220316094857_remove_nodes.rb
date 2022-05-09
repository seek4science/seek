class RemoveNodes < ActiveRecord::Migration[5.2]
  def change
    drop_table "node_auth_lookup" do |t|
      t.integer "user_id"
      t.integer "asset_id"
      t.boolean "can_view", default: false
      t.boolean "can_manage", default: false
      t.boolean "can_edit", default: false
      t.boolean "can_download", default: false
      t.boolean "can_delete", default: false
      t.index ["user_id", "asset_id", "can_view"], name: "index_n_auth_lookup_on_user_id_and_asset_id_and_can_view"
      t.index ["user_id", "can_view"], name: "index_n_auth_lookup_on_user_id_and_can_view"
    end

    drop_table "node_versions", id: :integer do |t|
      t.integer "node_id"
      t.integer "version"
      t.text "revision_comments"
      t.integer "contributor_id"
      t.string "title"
      t.text "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "last_used_at"
      t.string "first_letter", limit: 1
      t.text "other_creators"
      t.string "uuid"
      t.integer "policy_id"
      t.string "doi"
      t.string "license"
      t.string "deleted_contributor"
      t.integer "visibility"
      t.index ["contributor_id"], name: "index_node_versions_on_contributor"
      t.index ["node_id"], name: "index_node_versions_on_node_id"
    end

    drop_table "node_versions_projects", id: false do |t|
      t.integer "project_id"
      t.integer "version_id"
    end

    drop_table "nodes", id: :integer do |t|
      t.integer "contributor_id"
      t.string "title"
      t.text "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "last_used_at"
      t.integer "version", default: 1
      t.string "first_letter", limit: 1
      t.text "other_creators"
      t.string "uuid"
      t.integer "policy_id"
      t.string "doi"
      t.string "license"
      t.string "deleted_contributor"
      t.index ["contributor_id"], name: "index_nodes_on_contributor"
    end

    drop_table "nodes_projects", id: false do |t|
      t.integer "project_id"
      t.integer "node_id"
    end
  end
end
