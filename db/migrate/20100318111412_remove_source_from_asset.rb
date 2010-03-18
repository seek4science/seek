class RemoveSourceFromAsset < ActiveRecord::Migration
  def self.up
    remove_column(:assets, :source_id)
    remove_column(:assets, :source_type)
  end

  def self.down
    add_column :assets, :source_id, :integer
    add_column :assets, :source_type, :string
  end
end
