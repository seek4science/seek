class LinkTechnologyTypeToAssay < ActiveRecord::Migration
  
  def self.up
    add_column :assays, :technology_type_id, :integer
  end

  def self.down
    remove_column :assays,:technology_type_id
  end
  
end
