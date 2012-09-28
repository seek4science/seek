class CreateResourcePublishLogs < ActiveRecord::Migration
    def self.up
      create_table :resource_publish_logs, :force => true do |t|
        t.string "resource_type"
        t.integer "resource_id"
        t.string "culprit_type"
        t.integer "culprit_id"
        t.string "publish_state"
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    end

    def self.down
      drop_table :resource_publish_logs
    end
end
