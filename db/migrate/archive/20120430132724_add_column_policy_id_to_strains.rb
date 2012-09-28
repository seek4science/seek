class AddColumnPolicyIdToStrains < ActiveRecord::Migration
  def self.up
    add_column :strains, :policy_id, :integer
  end

  def self.down
    remove_column :strains, :policy_id
  end
end
