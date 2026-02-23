class CreateEventTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :event_types do |t|
      t.string :title, null: false
      t.text :description
    end
    add_index :event_types, :title, unique: true
  end
end
