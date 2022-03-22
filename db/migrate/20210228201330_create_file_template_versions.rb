class CreateFileTemplateVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :file_template_versions, force: :cascade do |t|
      t.integer :file_template_id
      t.integer :version
      t.text :revision_comments
      t.text :title
      t.text :description
      t.string :contributor_type
      t.integer :contributor_id
      t.string :first_letter, limit: 1
      t.string :uuid
      t.references :policy
      t.string :doi
      t.string :license
      t.datetime :last_used_at
      t.text "other_creators"
      t.integer :visibility
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "file_template_versions", ["contributor_id"], name: "index_ft_versions_on_contributor", using: :btree
    add_index "file_template_versions", ["file_template_id"], name: "index_ft_versions_on_ft_id", using: :btree
  end
end
