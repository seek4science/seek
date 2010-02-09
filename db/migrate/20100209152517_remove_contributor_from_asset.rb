class RemoveContributorFromAsset < ActiveRecord::Migration

  def self.up
    remove_column(:assets, :contributor_type)
    remove_column(:assets, :contributor_id)
  end

  def self.down
    add_column :assets, :contributor_type, :string
    add_column :assets, :contributor_id, :integer
  end
  
end
