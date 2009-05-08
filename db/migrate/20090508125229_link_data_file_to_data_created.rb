class LinkDataFileToDataCreated < ActiveRecord::Migration
  def self.up
    add_column(:data_files, :created_data_id, :integer)
  end

  def self.down
    remove_column(:data_files, :created_data_id)
  end
end
