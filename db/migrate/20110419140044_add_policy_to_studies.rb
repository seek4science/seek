class AddPolicyToStudies < ActiveRecord::Migration
  def self.up
    add_column :studies, :policy_id, :integer
  end

  def self.down
    remove_column :studies, :policy_id
  end
end
