class AddLicenseToDataFileVersions < ActiveRecord::Migration
  def change
    add_column :data_file_versions, :license, :string
  end
end
