class AddPrimaryKeyToAssetsCreators < ActiveRecord::Migration
  def self.up
    add_column :assets_creators, :id, :primary_key
  end

  def self.down
    remove_column :assets_creators, :id
  end
end
