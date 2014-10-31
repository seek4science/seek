class ChangeAssetDoiLogActionToAnInteger < ActiveRecord::Migration
  def up
    change_column :asset_doi_logs,:action,:integer
  end

  def down
    change_column :asset_doi_logs,:action,:string
  end
end
