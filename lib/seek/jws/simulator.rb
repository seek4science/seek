module Seek
  module Jws
    module Simulator
      extend ActiveSupport::Concern

      included do
        include Seek::Jws::Interaction
        include Seek::ExternalServiceWrapper
        before_action :find_display_asset_for_jws, only: [:simulate]
        before_action :jws_enabled, only: [:simulate]
        skip_after_action :log_event, if: -> (c) { c.action_name == 'simulate' && @constraint_based.nil? }
      end

      def simulate
        if @constraint_based = params[:constraint_based]
          wrap_service('JWS online', model_path(@model, version: @display_model.version)) do
            slug = upload_model_blob(@blob, @constraint_based == '1')
            if slug
              @simulate_url = model_simulate_url_from_slug(slug)
            else
              @jws_error = "JWS Online was unable to parse the SBML during upload"
            end
          end
        end
      end

      def find_display_asset_for_jws
        find_display_asset
        @blob = @display_model.jws_supported_content_blobs.first
        error('Unable to find JWS Online-compatible file', '') if @blob.nil?
      end
    end
  end
end
