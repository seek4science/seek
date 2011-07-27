class DropSubstanceInStudiedFactorsTable < ActiveRecord::Migration
  def self.up
    remove_column :studied_factors,:substance_type
    remove_column :studied_factors,:substance_id
  end

  def self.down
    add_column :studied_factors,:substance_type ,:string
    add_column :studied_factors,:substance_id ,:integer
  end
end
