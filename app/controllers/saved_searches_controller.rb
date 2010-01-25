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
  
end
