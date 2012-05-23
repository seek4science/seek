class AddPriorityToAuthUpdateQueue < ActiveRecord::Migration
  def self.up
    add_column :auth_lookup_update_queues,:priority, :integer, :default=>0
  end

  def self.down
    remove_column :auth_lookup_update_queues,:priority
  end
end
