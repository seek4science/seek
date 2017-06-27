class ChangeAssayOwnerToContributor < ActiveRecord::Migration
  def change
    rename_column :assays, :owner_id, :contributor_id
  end
end
