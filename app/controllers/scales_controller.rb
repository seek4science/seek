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
    @scaled_objects = @scale ? @scale.scalings.collect(&:scalable).compact.uniq : everything

    resource_hash={}

    grouped_result = @scaled_objects.group_by{|res| res.class.name}
    grouped_result.each do |key,value|
      resource_hash[key] = value
    end

=begin
    @scaled_objects.each do |res|
      resource_hash[res.class.name] = {:items => [], :hidden_count => 0} unless resource_hash[res.class.name]
      resource_hash[res.class.name][:items] << res
    end

    resource_hash.each do |key,res|
      res[:items].compact!      
      unless res[:items].empty?
        total_count = res[:items].size
        res[:items] = key.constantize.authorized_partial_asset_collection res[:items], "view", User.current_user
        res[:hidden_count] = total_count - res[:items].size
      end
    end
=end

    render :update do |page|
      scale_title = @scale.try(:title) || 'all'
      page.replace_html "#{scale_title}_results", :partial=>"assets/resource_listing_tabbed_by_class_lightweight", :locals =>{:resource_hash=>resource_hash,
                                                                                                                  :narrow_view => true,
                                                                                                                  :authorization_already_done => false,
                                                                                                                  :limit => 5,
                                                                                                                  :tabs_id => "#{scale_title}_resource_listing_tabbed_by_class",
                                                                                                                  :actions_partial_disable => true}
      #page.replace_html "js_for_tabber", :partial => "assets/force_loading_tabber"
    end

   end


  private

   def everything
    Seek::Util.user_creatable_types.inject([]) do |items, klass|
      items + klass.all
    end
  end

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end
end
