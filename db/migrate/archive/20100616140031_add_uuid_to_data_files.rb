class AddUuidToDataFiles < ActiveRecord::Migration
  def self.up
    add_column :data_files, :uuid, :string
  end

  def self.down
    remove_column :data_files,:uuid
  end
end
