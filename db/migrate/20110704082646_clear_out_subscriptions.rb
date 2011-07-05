class ClearOutSubscriptions < ActiveRecord::Migration
  def self.up
    drop_table :subscriptions
    drop_table :specific_subscriptions
  end

  def self.down
    create_table :subscriptions do |t|
      t.integer :person_id
      t.integer :project_id
      t.string :subscribed_resource_types
      t.integer :subscription_type, :limit => 1, :default=>0
      t.date :next_sent
    end

    create_table :specific_subscriptions do |t|
      t.integer :person_id
      t.string :subscribable_type
      t.integer :subscribable_id
      t.integer subscription_type, :default => 0
      t.timestamps
    end
  end
end
