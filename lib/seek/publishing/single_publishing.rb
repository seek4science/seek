module Seek
  module Publishing
    module SinglePublishing
      def self.included(base)
        base.before_filter :set_asset, :only=>[:single_publishing_preview,:single_publish]
      end

      def single_publishing_preview
        respond_to do |format|
          format.html { render :template=>"assets/publishing/single_publishing_preview" }
        end
      end

      private

      def set_asset
        begin
          @asset = self.controller_name.classify.constantize.find_by_id(params[:id])
        rescue ActiveRecord::RecordNotFound
          error("This resource is not found","not found resource")
        end
      end
    end
  end
end