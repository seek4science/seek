class AddContributorAndPolicyIdToInvestigations < ActiveRecord::Migration
  def self.up
    add_column :investigations, :policy_id, :integer
    add_column :investigations, :contributor_id, :integer
    add_column :investigations, :contributor_type, :string
  end

  def self.down
    remove_column :investigations, :policy_id, :contributor_id, :contributor_type
  end
end
