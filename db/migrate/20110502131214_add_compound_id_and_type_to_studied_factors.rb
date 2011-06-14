class AddCompoundIdAndTypeToStudiedFactors < ActiveRecord::Migration
  def self.up
    add_column :studied_factors,:compound_id, :integer
    add_column :studied_factors,:compound_type, :string
  end

  def self.down
    remove_column :studied_factors,:compound_id
    remove_column :studied_factors,:compound_type
  end
end
