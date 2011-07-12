class FavouritesController < ApplicationController
  
  before_filter :login_required

  cache_sweeper :favourites_sweeper,:only=>[:add,:delete]
  
  def add
    if request.post?
      if params[:id]=="drag_search" #needs to creat the SavedSearch resource first
        saved_search = SavedSearch.new(:user_id => current_user.id, :search_query => params[:search_query], :search_type => params[:search_type])
        if SavedSearch.find_by_user_id_and_search_query_and_search_type(current_user,params[:search_query],params[:search_type]).nil? && saved_search.save
          resource=saved_search
        end
      else
        split_id=params[:id].split("_")
        resource = split_id[1].constantize.find_by_id(split_id[2].to_i)
      end
    end
    resource ||= nil
    f=Favourite.new
    f.user=current_user
    f.resource = resource
        
    if resource && resource.is_favouritable? && Favourite.find_by_user_id_and_resource_type_and_resource_id(current_user,f.resource_type,f.resource_id).nil? && f.save
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
    if request.delete?
      id=params[:id].split("_")[1].to_i
      f=Favourite.find(id)
      f.resource.destroy if f.resource.instance_of?(SavedSearch)
    end

    if !f.nil? and f.user==current_user
      f.destroy
      render :update do |page|
          page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
          page.visual_effect :highlight, "drop_favourites", :startcolor=>"#DDDDFF"
      end 
    else
      render :update, :status=>:unprocessable_entity do |page|
        page.visual_effect :highlight, "drop_favourites", :startcolor=>"#FF0000"
      end
    end
  end
  
end
