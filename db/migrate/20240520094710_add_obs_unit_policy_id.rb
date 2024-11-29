class AddObsUnitPolicyId < ActiveRecord::Migration[6.1]
  def change
    add_column :observation_units, :policy_id, :bigint
  end
end
