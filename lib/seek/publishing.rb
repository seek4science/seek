module Seek
  module Publishing

    def self.included(base)
      base.before_filter :set_asset, :only=>[:preview_publish,:publish]
    end

    def preview_publish
      asset_type_name = @template.text_for_resource @asset

      respond_to do |format|
        format.html { render :template=>"assets/publish/preview",:locals=>{:asset_type_name=>asset_type_name} }
      end
    end

    def publish
      items_for_publishing = resolve_publish_params params[:publish]
      items_for_publishing << @asset unless items_for_publishing.include? @asset
      @notified_items = items_for_publishing.select{|i| !i.can_manage?}
      @published_items = items_for_publishing - @notified_items

      @problematic_items = @published_items.select{|item| !item.publish!}

      @published_items = @published_items - @problematic_items

      respond_to do |format|
        flash[:notice]="Publishing complete"
        format.html { render :template=>"assets/publish/published" }
      end
    end

    def set_asset
      c = self.controller_name.downcase
      @asset = eval("@"+c.singularize)
    end

    private

    #returns an enumeration of assets, or ISA elements, for publishing based upon the parameters passed

    def resolve_publish_params param
      return [] if param.nil?

      assets = []

      param.keys.each do |asset_class|
        param[asset_class].keys.each do |id|
          assets << eval("#{asset_class}.find_by_id(#{id})")
        end
      end
      assets.compact.uniq
    end

  end
end