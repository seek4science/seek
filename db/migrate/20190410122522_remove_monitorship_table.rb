class RemoveMonitorshipTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :monitorships
  end

  def down
    create_table "monitorships", id: :integer,  force: :cascade do |t|
      t.integer "topic_id"
      t.integer "user_id"
      t.boolean "active", default: true
    end
  end
end
