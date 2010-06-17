class AddUuidToAssays < ActiveRecord::Migration
  def self.up
    add_column :assays, :uuid, :string
  end

  def self.down
    remove_column :assays,:uuid
  end
end
