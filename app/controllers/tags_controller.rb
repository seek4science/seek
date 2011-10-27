class TagsController < ApplicationController



  before_filter :find_tag,:only=>[:show]
  
  def show

    acceptable_attributes = ["expertise","tool","tag"]

    @tagged_objects = select_authorised @tag.annotations.with_attribute_name(acceptable_attributes).collect{|a| a.annotatable}.uniq

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

  def find_tag
    @tag = TextValue.find_by_id(params[:id])
    if @tag.nil?
      flash[:error]="The Tag does not exist"
      respond_to do |format|
        format.html { redirect_to all_anns_path }
        format.xml { head :status => 404 }
      end

    end
  end

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end

end