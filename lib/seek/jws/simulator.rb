module Seek
  module Jws
    module Simulator
      extend ActiveSupport::Concern

      included do
        include Seek::Jws::Interaction
        before_filter :find_display_asset_for_jws, only: [:simulate]
        before_filter :jws_enabled, only: [:simulate]
      end

      def simulate
        slug = upload_model_blob(select_jws_content_blob)
        @simulate_url = model_simulate_url_from_slug(slug)
        @no_sidebar=true
      end

      def select_jws_content_blob
        blob = @display_model.jws_supported_content_blobs.first
        fail 'Unable to find file to support JWS Online' unless blob
        blob
      end

      def find_display_asset_for_jws
        find_display_asset
      end
    end
  end
end
