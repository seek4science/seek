class DropCreatedDatas < ActiveRecord::Migration
  def self.up
    drop_table :created_datas
  end

  def self.down
    create_table "created_datas", :force => true do |t|
    t.string   "status"
    t.integer  "person_id"
    t.integer  "assay_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "data_file_id"
  end
  end
end
