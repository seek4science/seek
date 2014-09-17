class AddAssetColumnsToSweeps < ActiveRecord::Migration
  def change
    rename_column :sweeps, :user_id, :contributor_id
    add_column :sweeps, :contributor_type, :string
    add_column :sweeps, :description, :text
    add_column :sweeps, :uuid, :string
    add_column :sweeps, :first_letter, :string, :limit => 1
    add_column :sweeps, :policy_id, :integer
  end
end
