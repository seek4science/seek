class AddZipOriginIdToDataFiles < ActiveRecord::Migration[6.1]
    def change
      add_column :data_files, :zip_origin_id, :integer
    end
  end
  