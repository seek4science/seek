class RemoveCultureGrowthFromAssay < ActiveRecord::Migration
  def self.up
    remove_column(:assays, :culture_growth_type_id)
  end

  def self.down
    add_column :assays,:culture_growth_type_id,:integer
  end
end
