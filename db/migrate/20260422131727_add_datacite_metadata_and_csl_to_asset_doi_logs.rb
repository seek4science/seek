class AddDataciteMetadataAndCslToAssetDoiLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :asset_doi_logs, :datacite_metadata, :text
  end
end
