class CreateAssays < ActiveRecord::Migration
  def self.up
    create_table :assays do |t|
      t.string :title      
      t.string :description      
      t.integer :assay_type_id

      t.timestamps
    end
  end

  def self.down
    drop_table :assays
  end
end
