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
    scalings = @scale.scalings.select { |s| !s.scalable.nil? }
    @scaled_objects = scalings.collect { |scaling| scaling.scalable }.uniq

    resource_hash={}
    @scaled_objects.each do |res|
      resource_hash[res.class.name] = {:items => [], :hidden_count => 0} unless resource_hash[res.class.name]
      resource_hash[res.class.name][:items] << res
    end
     resource_hash.each_value do |res|
        unless res[:items].empty?
        total_count = res[:items].size
        res[:items] = res[:items].select &:can_view?
        res[:hidden_count] = total_count - res[:items].size
      end
     end


    render :update do |page|
      page.replace_html "scaled_items_id", :partial=>"assets/resource_listing_tabbed_by_class", :locals =>{:resource_hash=>resource_hash, :narrow_view => true, :authorization_already_done => true}
      page.replace_html "js_for_tabber", :partial => "assets/force_loading_tabber"
    end

   end


  private

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end
end
