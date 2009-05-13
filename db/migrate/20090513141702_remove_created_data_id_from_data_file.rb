class RemoveCreatedDataIdFromDataFile < ActiveRecord::Migration
  def self.up
    remove_column(:data_files, :created_data_id)
  end

  def self.down
    add_column :data_files,:created_data_id,:integer
  end
end
