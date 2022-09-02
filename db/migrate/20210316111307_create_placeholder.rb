class CreatePlaceholder < ActiveRecord::Migration[5.2]
  def change
    create_table :placeholders, force: :cascade  do |t|
      t.text :title
      t.text :description
      t.integer  "contributor_id",      limit: 4
      t.string :first_letter, limit: 1
      t.string :uuid
      t.references :policy
      t.string :license
      t.datetime :last_used_at
      t.text :other_creators
      t.datetime "created_at"
      t.datetime "updated_at"
      t.references :file_template
      t.references :project
    end

    add_index "placeholders", ["contributor_id"], name: "index_ps_on_c", using: :btree

    add_column :placeholders, :data_type, :string, null: false, default: 'http://edamontology.org/data_0006'

    add_column :placeholders, :format_type, :string, null: false, default: 'http://edamontology.org/format_1915'
  end
end
