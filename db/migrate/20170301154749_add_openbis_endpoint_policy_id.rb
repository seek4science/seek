class AddOpenbisEndpointPolicyId < ActiveRecord::Migration
  def up
    add_column :openbis_endpoints,:policy_id,:integer
  end

  def down
    remove_column :openbis_endpoints, :policy_id
  end
end
