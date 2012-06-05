class CreateReindexingQueues < ActiveRecord::Migration
  def self.up
    create_table :reindexing_queues do |t|
      t.string :item_type
      t.integer :item_id

      t.timestamps
    end
  end

  def self.down
    drop_table :reindexing_queues
  end
end
