class AddDefaultPolicyToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :default_policy_id, :integer, :default => nil
  end

  def self.down
    remove_column :projects, :default_policy_id
  end
end
