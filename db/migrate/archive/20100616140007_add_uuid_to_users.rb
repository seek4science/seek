class AddUuidToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :uuid, :string
  end

  def self.down
    remove_column :users,:uuid
  end
end
