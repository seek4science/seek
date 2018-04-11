class DropTrashRecords < ActiveRecord::Migration
  def up
    drop_table :trash_records
  end

  def down
    create_table "trash_records", force: :cascade do |t|
      t.string   "trashable_type", limit: 255
      t.integer  "trashable_id",   limit: 4
      t.binary   "data",           limit: 16777215
      t.datetime "created_at"
    end

    add_index "trash_records", ["created_at", "trashable_type"], name: "index_trash_records_on_created_at_and_trashable_type"
    add_index "trash_records", ["trashable_type", "trashable_id"], name: "index_trash_records_on_trashable_type_and_trashable_id"
  end
end
