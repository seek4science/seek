class CreateFairDataStationUploads < ActiveRecord::Migration[7.2]
  def change
    create_table :fair_data_station_uploads do |t|
      t.bigint :contributor_id
      t.bigint :project_id
      t.bigint :investigation_id
      t.bigint :content_blob_id
      t.bigint :policy_id
      t.string :investigation_external_identifier, limit: 2048
      t.integer :purpose, limit: 2
      t.timestamps
    end
  end
end
