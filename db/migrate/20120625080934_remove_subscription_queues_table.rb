class RemoveSubscriptionQueuesTable < ActiveRecord::Migration
  def self.up
    drop_table :subscription_queues
  end

  def self.down
    create_table :subscription_queues do |t|
        t.integer :activity_log_id
        t.timestamps
    end
  end
end
