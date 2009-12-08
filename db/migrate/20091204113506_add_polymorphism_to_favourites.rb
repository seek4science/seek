class AddPolymorphismToFavourites < ActiveRecord::Migration
  def self.up
    rename_column(:favourites, :asset_id, :resource_id) 
    rename_column(:favourites, :model_name, :resource_type) 
  end

  def self.down
    rename_column(:favourites, :resource_id, :asset_id) 
    rename_column(:favourites, :resource_type, :model_name) 
  end
end
