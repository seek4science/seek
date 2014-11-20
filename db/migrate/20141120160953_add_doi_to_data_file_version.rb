class AddDoiToDataFileVersion < ActiveRecord::Migration
  def change
    add_column :data_file_versions,:doi,:string
  end
end
