class CreateAuthLookupUpdateQueues < ActiveRecord::Migration
  def self.up
    create_table :auth_lookup_update_queues do |t|
      t.integer :item_id
      t.string :item_type

      t.timestamps
    end
  end

  def self.down
    drop_table :auth_lookup_update_queues
  end
end
