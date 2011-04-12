class AddPolicyToAssays < ActiveRecord::Migration

  def self.up
    add_column :assays, :policy_id, :integer, :default => nil
  end

  def self.down
    remove_column :assays, :policy_id
  end
end
