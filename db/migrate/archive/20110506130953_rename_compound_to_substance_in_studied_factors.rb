class RenameCompoundToSubstanceInStudiedFactors < ActiveRecord::Migration
  def self.up
    rename_column :studied_factors, :compound_id, :substance_id
    rename_column :studied_factors, :compound_type, :substance_type
  end

  def self.down
    rename_column :studied_factors, :substance_id, :compound_id
    rename_column :studied_factors, :substance_type, :compound_type
  end
end
