class LinkCultureGrowthTypeToAssay < ActiveRecord::Migration
  def self.up
    add_column :assays, :culture_growth_type_id, :integer, :default=>0
  end

  def self.down
    remove_column :assays, :culture_growth_type_id
  end
end
