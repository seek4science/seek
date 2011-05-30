class AddUuidToSops < ActiveRecord::Migration
  def self.up
    add_column :sops, :uuid, :string
  end

  def self.down
    remove_column :sops,:uuid
  end
end
