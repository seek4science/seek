class CreateFavourites < ActiveRecord::Migration
  def self.up
    create_table :favourites do |t|
      t.integer :asset_id
      t.integer :user_id
      t.string :model_name
      t.timestamps
    end
  end

  def self.down
    drop_table :favourites
  end
end
