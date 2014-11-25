class AddDoiToAssetDoiLogs < ActiveRecord::Migration
  def change
    add_column :asset_doi_logs,:doi,:string
  end
end
