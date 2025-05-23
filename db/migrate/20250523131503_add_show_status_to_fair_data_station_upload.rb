class AddShowStatusToFairDataStationUpload < ActiveRecord::Migration[7.2]
  def change
    add_column :fair_data_station_uploads, :show_status, :boolean, default: true
  end
end
