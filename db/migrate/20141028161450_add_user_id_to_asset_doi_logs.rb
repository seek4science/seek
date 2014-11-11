class AddUserIdToAssetDoiLogs < ActiveRecord::Migration
  def change
    add_column(:asset_doi_logs, :user_id, :integer)
  end
end
