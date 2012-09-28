class AddCreatedAtUpdatedAtToAssetsCreators < ActiveRecord::Migration
  def self.up
    add_column :assets_creators, :created_at, :datetime
    add_column :assets_creators, :updated_at, :datetime
  end

  def self.down
    remove_columns :assets_creators, :created_at, :updated_at
  end
end
