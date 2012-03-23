class RemoveNcbiIdFromOrganism < ActiveRecord::Migration
  def self.up
    remove_column :organisms, :ncbi_id
  end

  def self.down
    add_column :organisms,:ncbi_id,:integer
  end
end
