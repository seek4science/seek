class CreateSampleControlledVocabularyAuthLookup < ActiveRecord::Migration[7.2]
  def change
    create_table :sample_controlled_vocab_auth_lookup do |t|
      t.integer :user_id
      t.integer :asset_id
      t.boolean :can_view,     :default => false
      t.boolean :can_manage,   :default => false
      t.boolean :can_edit,     :default => false
      t.boolean :can_download, :default => false
      t.boolean :can_delete,   :default => false
      t.timestamps
    end

    create_table :projects_sample_controlled_vocabs do |t|
      t.integer "project_id"
      t.integer "sample_controlled_vocab_id"
      t.index ["project_id"], name: "index_projects_sample_controlled_vocabs_on_project_id"
      t.index ["sample_controlled_vocab_id", "project_id"], name: "index_projects_sample_controlled_vocabs_on_cv_id_and_project_id"
    end

    add_index :sample_controlled_vocab_auth_lookup, [:user_id, :asset_id, :can_view], :name => "index_cv_auth_lookup_on_user_id_asset_id_can_view"
    add_index :sample_controlled_vocab_auth_lookup, [:user_id, :can_view], :name => "index_cv_auth_lookup_on_user_id_and_can_view"
    add_column :sample_controlled_vocabs, :policy_id, :integer
    add_column :sample_controlled_vocabs, :contributor_id, :integer
    add_column :sample_controlled_vocabs, :uuid, :string
    add_column :sample_controlled_vocabs, :external_identifier, :string, limit: 2048
    add_column :sample_controlled_vocabs, :other_creators, :text
    add_column :sample_controlled_vocabs, :deleted_contributor, :string
  end
end
