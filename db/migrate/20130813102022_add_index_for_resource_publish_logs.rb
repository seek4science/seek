class AddIndexForResourcePublishLogs < ActiveRecord::Migration
  def self.up
    add_index :resource_publish_logs, [:resource_type,:resource_id]
    add_index :resource_publish_logs, :user_id
    add_index :resource_publish_logs, :publish_state
  end

  def self.down
    remove_index :resource_publish_logs, [:resource_type,:resource_id]
    remove_index :resource_publish_logs, :user_id
    remove_index :resource_publish_logs, :publish_state
  end
end
