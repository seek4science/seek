class CreateEventsPublications < ActiveRecord::Migration
  def self.up
    create_table :events_publications, :id=>false do |t|
      t.integer :publication_id
      t.integer :event_id
    end
  end

  def self.down
    drop_table :events_publications
  end
end
