class AddOpenidToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :openid, :string
  end

  def self.down
    remove_column :users, :openid
  end
end
