class RemoveContributorFromPolicy < ActiveRecord::Migration
  def self.up
    remove_column(:policies, :contributor_type)
    remove_column(:policies, :contributor_id)
  end

  def self.down
    add_column :policies, :contributor_type, :string
    add_column :policies, :contributor_id, :integer
  end
end
