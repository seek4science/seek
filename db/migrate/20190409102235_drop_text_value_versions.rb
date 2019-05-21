class DropTextValueVersions < ActiveRecord::Migration[5.2]
  def up
    drop_table :text_value_versions
  end

  def down
    create_table "text_value_versions", id: :integer,  force: :cascade do |t|
      t.integer "text_value_id", null: false
      t.integer "version", null: false
      t.integer "version_creator_id"
      t.text "text", limit: 4294967295, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["text_value_id"], name: "index_text_value_versions_on_text_value_id"
    end
  end
end
