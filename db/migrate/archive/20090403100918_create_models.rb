class CreateModels < ActiveRecord::Migration
  def self.up
    create_table :models do |t|
      t.string :contributor_type
      t.integer :contributor_id
      t.string :title
      t.text :description
      t.string :original_filename
      t.integer :content_blob_id
      t.string :content_type
      t.string :model_type
      t.string :model_format
      t.integer :recommended_environment_id
      t.text :result_graph
      t.datetime :last_used_at

      t.timestamps
    end
  end

  def self.down
    drop_table :models
  end
end
