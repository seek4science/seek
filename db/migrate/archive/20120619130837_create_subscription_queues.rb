class CreateSubscriptionQueues < ActiveRecord::Migration
  def self.up
    create_table :subscription_queues do |t|
      t.integer :activity_log_id
      t.timestamps
    end
  end

  def self.down
    drop_table :subscription_queues
  end
end
