class CreateModelImages < ActiveRecord::Migration
  def self.up
    create_table :model_images do |t|
      t.integer :model_id
      t.integer :model_version
      t.string :original_filename
      t.string :original_content_type
      t.timestamps
    end
  end

  def self.down
    drop_table :model_images
  end
end
