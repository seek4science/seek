class ChangeAssetDoiLogActionToAnInteger < ActiveRecord::Migration
  def up
    if ActiveRecord::Base.connection.class.name=="ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
      change_column :asset_doi_logs,:action,'integer USING CAST(action as integer)'
    else
      change_column :asset_doi_logs,:action,:integer
    end
  end

  def down
    change_column :asset_doi_logs,:action,:string
  end
end
