class AddUuidToEvent < ActiveRecord::Migration
  def self.up
    add_column :events, :uuid, :string
  end

  def self.down
    remove_column :events, :uuid
  end
end
