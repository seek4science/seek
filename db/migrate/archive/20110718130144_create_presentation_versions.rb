class CreatePresentationVersions < ActiveRecord::Migration
  def self.up
    create_table :presentation_versions do |t|
      t.integer  :presentation_id
      t.integer  :version
      t.text     :revision_comments
      t.string   :contributor_type
      t.integer  :contributor_id
      t.string   :title
      t.text     :description
      t.string   :original_filename
      t.string   :content_type
      t.integer  :content_blob_id
      t.timestamps

      t.datetime :last_used_at
      t.string   :first_letter,      :limit => 1
      t.text     :other_creators
      t.string   :uuid
      t.integer  :project_id
      t.integer  :policy_id
    end
  end

  def self.down
    drop_table :presentation_versions
  end
end
