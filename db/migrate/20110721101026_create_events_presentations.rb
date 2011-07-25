class CreateEventsPresentations < ActiveRecord::Migration
  def self.up
    create_table :events_presentations,:id=>false do |t|
      t.integer :presentation_id
      t.integer :event_id
    end
  end

  def self.down
    drop_table :events_presentations
  end
end
