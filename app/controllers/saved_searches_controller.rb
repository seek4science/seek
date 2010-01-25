class SavedSearchesController < ApplicationController

  def show
    saved_search = SavedSearch.find_by_id(params[:id])

    respond_to do |format|
      if saved_search
        #params[:search_query] = saved_search.search_query
        #params[:search_type] = saved_search.search_query
        format.html { redirect_to(:controller=>"search",:action => "index", :search_query => saved_search.search_query,
            :search_type => saved_search.search_type,
            :saved_search => true)}
        format.xml  { head :ok }
      else
        flash[:error]="Couldn't find the requested search."
        format.html { redirect_to :back }
      end
    end
  end

  def create
    saved_search = SavedSearch.new(:user_id => current_user.id, :search_query => params[:search_query], :search_type => params[:search_type])    
    if SavedSearch.find_by_user_id_and_search_query_and_search_type(current_user,params[:search_query],params[:search_type]).nil? && saved_search.save
      favourite=Favourite.new
      favourite.resource=saved_search
      favourite.user=current_user
      if favourite.save
        render :update, :status=>:created do |page|
          page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
          page.visual_effect :highlight, "drop_favourites", :startcolor=>"#DDDDFF"
        end
      else
        saved_search.delete
        render :update, :status=>:unprocessable_entity do |page|
          page.visual_effect :highlight, "drop_favourites", :startcolor=>"#FF0000"
        end
      end
    else
      render :update, :status=>:unprocessable_entity do |page|
        page.visual_effect :highlight, "drop_favourites", :startcolor=>"#FF0000"
      end
    end
  end

  def delete
    id=params[:id].split("_")[1].to_i
    s=SavedSearch.find(id)
    if !s.nil? and s.user==current_user
      s.destroy
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
