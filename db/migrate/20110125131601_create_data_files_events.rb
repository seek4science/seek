class CreateDataFilesEvents < ActiveRecord::Migration
  def self.up
    create_table :data_files_events, :id=>false do |t|
      t.integer :data_file_id
      t.integer :event_id
    end
  end

  def self.down
    drop_table :data_files_events
  end
end
