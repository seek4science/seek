class AddStatusIdToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :status_id, :integer, :default=>0
  end

  def self.down
    remove_column :people, :status_id
  end
end
