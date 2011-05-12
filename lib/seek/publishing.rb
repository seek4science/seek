module Seek
  module Publishing

    def self.included(base)
      #base.before_filter :find_asset_to_publish, :only=>[:preview_publish]
    end

    def preview_publish
      c = self.controller_name.downcase

      @asset = eval("@"+c.singularize)
      asset_type_name = @template.text_for_resource @asset

      respond_to do |format|
        format.html { render :template=>"assets/preview_publish",:locals=>{:asset_type_name=>asset_type_name} }
      end
    end

  end
end