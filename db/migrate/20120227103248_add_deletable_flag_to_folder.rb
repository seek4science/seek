class AddDeletableFlagToFolder < ActiveRecord::Migration
  def self.up
    add_column :project_folders, :deletable, :boolean, :default=>true
  end

  def self.down
    remove_column :project_folders,:folders, :deletable
  end
end
