class CreateHelpImages < ActiveRecord::Migration
  def self.up
    create_table :help_images do |t|
      t.integer :help_document_id
      t.string :content_type
      t.string :filename 
      t.integer :size
      t.integer :height
      t.integer :width
      t.integer :parent_id
      t.string :thumbnail
      t.timestamps
    end
  end

  def self.down
    drop_table :help_images
  end
end
