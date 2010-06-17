class AddUuidToDataFileVersions < ActiveRecord::Migration
  def self.up
    add_column :data_file_versions, :uuid, :string
  end

  def self.down
    remove_column :data_file_versions,:uuid
  end
end
