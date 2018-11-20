class ScalesController < ApplicationController
  include Seek::IndexPager

  before_action :find_assets,:only => [:index]

  def index
    respond_to do |format|
      format.html
    end
  end

  def search
    type = params[:scale_type]
    scale = Scale.find_by_key(type)

    assets = scale ? Scale.with_scale(scale) : everything_with_scale

    @scale_title = scale.try(:key) || 'all'
    @resource_hash = build_resource_hash(assets)
    respond_to do |format|
      format.js
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
