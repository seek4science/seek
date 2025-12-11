class AddEventTypeToEvents < ActiveRecord::Migration[7.2]
  def change
    add_reference :events, :event_type, foreign_key: true, index: true, null: true
  end
end
