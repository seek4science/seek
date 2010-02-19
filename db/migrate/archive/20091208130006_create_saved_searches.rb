class CreateSavedSearches < ActiveRecord::Migration
  def self.up
    create_table :saved_searches do |t|
      t.integer :user_id
      t.text :search_query
      t.text :search_type
      t.timestamps
    end
  end

  def self.down
    drop_table :saved_searches
  end
end
