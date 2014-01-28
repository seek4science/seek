class CreateSpecificSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :specific_subscriptions do |t|
      t.integer :person_id
      t.string  :subscribable_type
      t.integer :subscribable_id
      t.timestamps

    end

  end

  def self.down
    drop_table :specific_subscriptions
  end
end
