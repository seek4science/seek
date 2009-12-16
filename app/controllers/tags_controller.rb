class TagsController < ApplicationController
  def show
    @tag = Tag.find_by_id(params[:id])
    taggings = @tag.taggings
    @tagged_objects = select_authorised taggings.collect{|tagging| tagging.taggable}
    
    if @tagged_objects.empty?
      flash.now[:notice]="No objects found with tag '<b>#{@tag.name}</b>'."
    else
      flash.now[:notice]="#{@tagged_objects.size} #{@tagged_objects.size==1 ? 'item' : 'items'} found with tag '<b>#{@tag.name}</b>'."
    end
    respond_to do |format|
      format.html # show.html.erb
    end    
  end
  
  private  

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
  end
end