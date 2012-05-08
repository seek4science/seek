class AddIncomingFlagToProjectFolder < ActiveRecord::Migration
  def self.up
    add_column :project_folders, :incoming, :boolean, :default=>false
  end

  def self.down
    remove_column :project_folders, :incoming
  end
end
