class ScalesController < ApplicationController
  include Seek::IndexPager

  before_filter :find_assets,:only => [:index]


  def index
    respond_to do |format|
      format.html
    end
  end
  def search
    type = params[:scale_type]
        scale = Scale.find_by_key(type)

        assets = scale ? Scale.with_scale(scale) : everything_with_scale

        resource_hash =  build_resource_hash(assets)

        render :update do |page|
          scale_title = scale.try(:key) || 'all'
          page.replace_html "#{scale_title}_results", :partial=>"assets/resource_listing_tabbed_by_class", :locals =>{:resource_hash=>resource_hash,
                                                                                                                      :show_empty_tabs=>true,
                                                                                                                      :narrow_view => true, :authorization_already_done => true,
                                                                                                                      :limit => 20,
                                                                                                                      :tabs_id => "#{scale_title}_resource_listing_tabbed_by_class",
                                                                                                                      :actions_partial_disable => true, :display_immediately=>true}
          page << "load_tabs();"
        end
  end


  def search_and_lazy_load_results
    type = params[:scale_type]
    scale = Scale.find_by_key(type)

    assets = scale ? Scale.with_scale(scale) :   everything_with_scale

    resource_hash={}
    grouped_assets = assets.group_by { |asset| asset.class.name }
    grouped_assets.each do |asset_type, items|
      resource_hash[asset_type] = items if items.count > 0
    end if !grouped_assets.blank?

    render :update do |page|
      scale_title = scale.try(:key) || 'all'
      page.replace_html "#{scale_title}_results", :partial => "assets/resource_tabbed_lazy_loading",
                        :locals => {:scale_title => scale_title,
                                    :tabs_id => "resource_tabbed_lazy_loading_#{scale_title}",
                                    :resource_hash => resource_hash}

    end
  end

  def show
      @scale_key=Scale.find_by_id(params[:id]).try(:key) || "all"
    end

  private

  def everything_with_scale
        Scale.all.collect do |scale|
          scale.assets
        end.flatten.uniq
  end

   def everything_in_seek
       Seek::Util.user_creatable_types.map do |klass|
             klass.all
       end.flatten.uniq
   end

  def build_resource_hash(assets)
      resource_hash={}
      assets.each do |res|
        resource_hash[res.class.name] = {:items => [], :hidden_count => 0} unless resource_hash[res.class.name]
        resource_hash[res.class.name][:items] << res
      end

      resource_hash.each do |key, res|
        res[:items] = res[:items].compact
        unless res[:items].empty?
          total_count = res[:items].size
          all = res[:items]
          res[:items] = key.constantize.authorize_asset_collection res[:items], "view"
          res[:hidden_count] = total_count - res[:items].size
          res[:hidden_items] = all - res[:items]
        end
      end
      resource_hash
  end
  
end
