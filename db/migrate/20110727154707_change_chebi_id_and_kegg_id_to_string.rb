class ChangeChebiIdAndKeggIdToString < ActiveRecord::Migration
  def self.up
    change_column :mappings, :chebi_id, :string
    change_column :mappings, :kegg_id, :string
  end
  def self.down
    change_column :mappings, :chebi_id, :integer
    change_column :mappings, :kegg_id, :integer
  end
end
