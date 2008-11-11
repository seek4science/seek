class FavouritesController < ApplicationController
  def add
    full_id=params[:id]
    f=Favourite.new
    f.user=current_user
    f.asset_id=full_id.split("_").last.to_i
    f.save
    
  end
end
