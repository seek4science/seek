class CreateFileTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :file_templates, force: :cascade do |t|
      t.text :title
      t.text :description
      t.integer  "contributor_id",      limit: 4
      t.integer :version
      t.string :first_letter, limit: 1
      t.string :uuid
      t.references :policy
      t.string :doi
      t.string :license
      t.datetime :last_used_at
      t.text :other_creators
      t.datetime "created_at"
      t.datetime "updated_at"
    end

#    add_index "file_templates", ["contributor_id"], name: "index_file_templates_on_contributor", using: :btree

  end
end
