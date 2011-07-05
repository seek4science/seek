class AddSubscriptionTypeAndProjectIdToSpecificSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :specific_subscriptions,:subscription_type,:integer,:default => 0
    add_column :specific_subscriptions,:project_id,:integer
  end

  def self.down
    remove_column :specific_subscriptions,:subscription_type
    remove_column :specific_subscriptions,:project_id
  end
end
