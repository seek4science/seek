class CreateSubscriptionTables < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.integer :person_id
      t.integer :subscribable_id
      t.string :subscribable_type
      t.string :subscription_type
      t.timestamps
    end

    create_table :project_subscriptions do |t|
      t.integer :person_id
      t.integer :project_id
      t.string :unsubscribed_types
      t.string :frequency
    end
    
  end

  def self.down
    drop_table :subscriptions
    drop_table :project_subscriptions
  end
end
