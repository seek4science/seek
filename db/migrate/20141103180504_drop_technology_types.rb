class DropTechnologyTypes < ActiveRecord::Migration
  def up
    drop_table :technology_types
  end

  def down
    create_table "technology_types", :force => true do |t|
      t.string   "title"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "term_uri"
      t.string   "source_path"
      t.integer  "contributor_id"
    end
  end
end
