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
      respond_to do |format|
        flash[:notice]="Publishing completed"
        format.html { redirect_to @asset }
      end
    end

    def set_asset
      c = self.controller_name.downcase
      @asset = eval("@"+c.singularize)
    end

  end
end