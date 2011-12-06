class CreateStudiedFactorLinks < ActiveRecord::Migration
  def self.up
    create_table :studied_factor_links do |t|
      t.string :substance_type
      t.integer :substance_id
      t.integer :studied_factor_id

      t.timestamps
    end
  end

  def self.down
    drop_table :studied_factor_links
  end
end
