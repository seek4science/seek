class AddUuidToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :uuid, :string
  end

  def self.down
    remove_column :projects,:uuid
  end
end
