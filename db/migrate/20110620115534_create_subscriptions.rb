class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.integer :person_id
      t.integer :project_id
      t.string :subscribed_resource_types
      t.integer :subscription_type,:limit => 1,:default=>0
      t.date :next_sent

    end
  end

  def self.down
    drop_table :subscriptions
  end
end
