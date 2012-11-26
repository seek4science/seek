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
    @scaled_objects.each do |res|
      resource_hash[res.class.name] = {:items => [], :hidden_count => 0} unless resource_hash[res.class.name]
      resource_hash[res.class.name][:items] << res
    end

    resource_hash.each do |key,res|
      unless res[:items].empty?
        total_count = res[:items].size
        res[:items] = authorized_related_items res[:items], key
        res[:hidden_count] = total_count - res[:items].size
      end
    end

    render :update do |page|
      scale_title = @scale.try(:title) || 'all'
      page.replace_html "#{scale_title}_results", :partial=>"assets/resource_listing_tabbed_by_class", :locals =>{:resource_hash=>resource_hash, 
                                                                                                                  :narrow_view => true, :authorization_already_done => true, 
                                                                                                                  :limit => 20,
                                                                                                                  :tabs_id => "#{scale_title}_resource_listing_tabbed_by_class",
                                                                                                                  :actions_partial_disable => true}
      page.replace_html "js_for_tabber", :partial => "assets/force_loading_tabber"
    end

   end

  #FIXME: refractor this method with the method in assets_helper
  def authorized_related_items related_items, item_type
    user_id = current_user.nil? ? 0 : current_user.id
    assets = []
    authorized_related_items = []
    lookup_table_name = item_type.underscore + 'auth_lookup'
    asset_class = item_type.constantize
    if (asset_class.lookup_table_consistent?(user_id))
      Rails.logger.info("Lookup table #{lookup_table_name} used for authorizing related items is complete for user_id = #{user_id}")
      assets = asset_class.lookup_for_action_and_user 'view', user_id, nil
      authorized_related_items = assets & related_items
    else
      authorized_related_items = related_items.select(&:can_view?)
    end
    authorized_related_items
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
