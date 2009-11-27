class AddAuthorIdToAssets < ActiveRecord::Migration
  
  def self.up
    add_column :assets, :author_id, :integer  
  end

  def self.down
    remove_column :assets, :author_id
  end
end
