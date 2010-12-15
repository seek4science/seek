class RemoveQualityFromAsset < ActiveRecord::Migration
  def self.up
    remove_column(:assets, :quality)
  end

  def self.down
    add_column :assets,:quality,:string
  end
end
