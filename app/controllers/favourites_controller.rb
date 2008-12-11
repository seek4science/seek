class FavouritesController < ApplicationController
  
  before_filter :login_required
  
  def add
    #FIXME validate id with a regular expression
    split_id=params[:id].split("_")
    f=Favourite.new
    f.user=current_user
    f.model_name=split_id[1]
    f.asset_id=split_id[2].to_i
    
    if Favourite.find_by_user_id_and_model_name_and_asset_id(current_user,f.model_name,f.asset_id).nil?
      f.save
      render :update, :status=>:created do |page|
          page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
          page.visual_effect :highlight, "drop_favourites", :startcolor=>"#DDDDFF"
      end
    else
      render :update, :status=>:unprocessable_entity do |page|
        page.visual_effect :highlight, "drop_favourites", :startcolor=>"#FF0000"
      end
    end
    
  end
  
  def delete
    id=params[:id].split("_")[1].to_i
    f=Favourite.find(id)
    if !f.nil? and f.user==current_user
      f.destroy
      render :update do |page|
          page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
          page.visual_effect :highlight, "drop_favourites", :startcolor=>"#DDDDFF"
      end 
    else
      render :update do |page|
        page.visual_effect :highlight, "drop_favourites", :startcolor=>"#FF0000"
      end
    end
  end
  
end
