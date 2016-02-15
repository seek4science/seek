class AddLicenseToDataFiles < ActiveRecord::Migration
  def change
    add_column :data_files, :license, :string
  end
end
