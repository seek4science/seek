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

    @grouped_assets = scale ? scale.grouped_assets : everything_with_scale
    @scale_title = scale.try(:key) || 'all'

    respond_to do |format|
      format.js
    end
  end

  def show
    @scale_key=Scale.find_by_id(params[:id]).try(:key) || "all"
  end

  private

  def everything_with_scale
    grouped = {}

    Scale.find_each do |scale|
      scale.grouped_asset_ids.each do |type, ids|
        grouped[type] ||= []
        grouped[type] |= ids
      end
    end

    grouped.each do |key, ids|
      grouped[key] = key.constantize.where(id: ids)
    end

    grouped
  end

  def everything_in_seek
    Seek::Util.user_creatable_types.map do |klass|
      klass.all
    end.flatten.uniq
  end
end
