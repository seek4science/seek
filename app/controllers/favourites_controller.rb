class FavouritesController < ApplicationController
  def add
    split_id=params[:id].split("_")
    f=Favourite.new
    f.user=current_user
    f.model_name=split_id[1]
    f.asset_id=split_id[2].last.to_i
    f.save
    
  end
end
