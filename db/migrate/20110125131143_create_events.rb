class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.datetime :start_date
      t.datetime :end_date
      t.text :address
      t.string :city
      t.string :country
      t.string :url
      t.text :description
      t.string :title
      t.integer :project_id
      t.integer :policy_id
      t.integer :contributor_id

      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
