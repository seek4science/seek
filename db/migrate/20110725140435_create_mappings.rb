class CreateMappings < ActiveRecord::Migration
  def self.up
    create_table :mappings do |t|
      t.integer :sabiork_id
      t.integer :chebi_id
      t.integer :kegg_id

      t.timestamps
    end
  end

  def self.down
    drop_table :mappings
  end
end
