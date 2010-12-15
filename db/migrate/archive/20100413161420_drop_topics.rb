class DropTopics < ActiveRecord::Migration
  def self.down
    create_table :topics do |t|
      t.string :title
      t.integer :project_id
      t.string :description

      t.timestamps
    end
  end

  def self.up
    drop_table :topics
  end
  
end
