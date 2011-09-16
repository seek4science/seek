class TagsController < ApplicationController
  
  def show
    @tag = TextValue.find(params[:id])
        
    @tagged_objects = select_authorised @tag.annotations.collect{|a| a.annotatable}.uniq

    if @tagged_objects.empty?
      flash.now[:notice]="No objects (or none that you are authorized to view) are tagged with '<b>#{@tag.text}</b>'."
    else
      flash.now[:notice]="#{@tagged_objects.size} #{@tagged_objects.size==1 ? 'item' : 'items'} tagged with '<b>#{@tag.text}</b>'."
    end
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def index
    respond_to do |format|
      format.html
    end
  end
  
  private  

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end

end