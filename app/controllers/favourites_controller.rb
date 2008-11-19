class FavouritesController < ApplicationController
  def add
    #TODO validate id, and only add if not a duplicate
    split_id=params[:id].split("_")
    f=Favourite.new
    f.user=current_user
    f.model_name=split_id[1]
    f.asset_id=split_id[2].to_i
    f.save
    render :update do |page|
        page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
        page.visual_effect :highlight, "drop_favourites", :startcolor=>"#DDDDFF"
    end
  end
  
  def delete
    id=params[:id].split("_")[1].to_i
    Favourite.find(id).destroy
    render :update do |page|
        page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
        page.visual_effect :highlight, "drop_favourites", :startcolor=>"#DDDDFF"
    end 
  end
end
