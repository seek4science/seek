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
    resource_hash = {}

    if @scale
      scalables = Scaling.find(:all, :include => :scalable, :conditions => ["scale_id=?", @scale.id]).collect(&:scalable).compact.uniq
      grouped_scalings = scalables.group_by { |scalable| scalable.class.name }
      grouped_scalings.each do |key, value|
        resource_hash[key] = value
      end if !grouped_scalings.blank?
    else
      Seek::Util.user_creatable_types.each do |klass|
        items = klass.all
        resource_hash["#{klass}"] = items if items.count > 0
      end
    end

    render :update do |page|
      scale_title = @scale.try(:title) || 'all'
      page.replace_html "#{scale_title}_results", :partial=>"assets/resource_tabbed_lazy_loading",
                        :locals =>{:scale_title => scale_title,
                                   :tabs_id => "resource_tabbed_lazy_loading_#{scale_title}",
                                   :resource_hash => resource_hash }
    end
   end


  private

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end
end
