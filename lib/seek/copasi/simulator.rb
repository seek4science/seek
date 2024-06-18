module Seek
  module Copasi
    module Simulator
      extend ActiveSupport::Concern

      included do
        before_action :find_display_asset_for_copasi, only: [:copasi_simulate]
      end

      def copasi_simulate
        @model = Model.find_by_id(params[:id])
        @content_blob =  @model.content_blobs.first
        render 'copasi_simulate'
      end

      def select_copasi_content_blob
      end

      def find_display_asset_for_copasi
        find_display_asset Model.find_by_id(params[:id])
      end
    end
  end
end

