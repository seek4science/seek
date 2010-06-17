class AddUuidToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :uuid, :string
  end

  def self.down
    remove_column :people,:uuid
  end
end
