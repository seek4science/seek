class CreateMappingLinks < ActiveRecord::Migration
  def self.up
    create_table :mapping_links do |t|
      t.string :substance_type
      t.integer :substance_id
      t.integer :mapping_id

      t.timestamps
    end
  end

  def self.down
    drop_table :mapping_links
  end
end
