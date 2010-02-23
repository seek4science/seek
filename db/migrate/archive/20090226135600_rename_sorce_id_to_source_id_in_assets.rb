class RenameSorceIdToSourceIdInAssets < ActiveRecord::Migration
  
  # Migration intended to fix a typo in the column name;
  # it's safe to do this at this point, because no code is capable of writing data to
  # that column at the moment
  
  def self.up
    rename_column :assets, :sorce_id, :source_id
  end

  def self.down
    rename_column :assets, :source_id, :sorce_id
  end
end
