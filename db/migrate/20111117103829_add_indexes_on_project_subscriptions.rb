class AddIndexesOnProjectSubscriptions < ActiveRecord::Migration
  
  def self.up
    add_index :project_subscriptions, [:person_id,:project_id]
  end

  def self.down
    remove_index :project_subscriptions, :column=>[:person_id,:project_id]
  end
end
