class CreateDataFiles < ActiveRecord::Migration
  def self.up
    create_table :data_files do |t|
      t.string :contributor_type
      t.integer :contributor_id
      t.string :title
      t.text :description
      t.string :original_filename
      t.string :content_type
      t.integer :content_blob_id
      t.integer :experiment_id
      t.integer :template_id

      t.datetime :last_used_at

      t.timestamps
    end
  end

  def self.down
    drop_table :data_files
  end
end
