class ScalesController < ApplicationController
  include IndexPager

  before_filter :find_assets,:only => [:index]
   def show
    @scale = Scale.find(params[:id])
    scalings = @scale.scalings.select{|s| !s.scalable.nil?}
    @scaled_objects = select_authorised scalings.collect{|scaling| scaling.scalable}.uniq

    if @scaled_objects.empty?
      flash.now[:notice]="No objects (or none that you are authorized to view) are scaled with '<b>#{@scale.name}</b>'."
    else
      flash.now[:notice]="#{@scaled_objects.size} #{@scaled_objects.size==1 ? 'item' : 'items'} scaled with '<b>#{@scale.name}</b>'."
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

   def scale_search
    @scale = Scale.find_by_title(params[:scale_type])
    render :update do |page|
      scale_title = @scale.try(:title) || 'all'
      page.replace_html "#{scale_title}_results", :partial=>"assets/resource_by_scale",
                        :locals =>{:scale_title => scale_title,
                                   :tabs_id => "resource_by_scale_#{scale_title}"}
    end
   end


  private

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end
end
