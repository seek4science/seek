class RemoveSessionsTable < ActiveRecord::Migration[7.2]
  def up
    drop_table :sessions
  end

  def down
    create_table :sessions, id: :integer do |t|
      t.string :session_id, null: false
      t.text :data, limit: 16_777_215
      t.datetime :created_at
      t.datetime :updated_at

      t.index :session_id, name: "index_sessions_on_session_id"
      t.index :updated_at, name: "index_sessions_on_updated_at"
    end
  end
end
