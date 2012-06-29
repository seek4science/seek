class AddProjectSubscriptionIdToSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :project_subscription_id, :integer
  end

  def self.down
    remove_column :subscriptions, :project_subscription_id
  end
end
