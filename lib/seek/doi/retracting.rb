module Seek
  module Doi
    module Retracting
      include Seek::ExternalServiceWrapper

      def self.included(base)
        base.before_action :set_doi_asset, only: %i[retract_doi_confirm retract_doi]
        base.before_action :retract_doi_auth, only: %i[retract_doi_confirm retract_doi]
      end

      def retract_doi_confirm
        respond_to do |format|
          format.html { render template: 'datacite_doi/retract_doi_confirm' }
        end
      end

      def retract_doi
        asset_path = polymorphic_path(@asset)
        retraction_reason = params[:retraction_reason].to_s.strip.presence

        wrap_service('DataCite', asset_path) do
          if @asset.retract_dois(retraction_reason) && @asset.destroy
            flash[:notice] = 'DOI successfully retracted'
          else
            flash[:error] = @asset.errors.full_messages.join(', ')
          end

          redirect_to root_path
        end
      end

      private

      # I can't do `def set_asset` because this method may already exist
      def set_doi_asset
        @asset = controller_model.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        error('This resource is not found', 'not found resource')
      end

      def retract_doi_auth
        unless @asset.can_manage?
          error('You are not authorized to retract the DOI for this resource', 'is invalid')
          return false
        end
        unless @asset.is_published?
          error('Cannot retract the DOI for an unpublished resource', 'is invalid')
          return false
        end
        unless @asset.can_retract_doi?
          error('Retracting the DOI is not possible', 'is invalid')
          return false
        end
        true
      end
    end
  end
end
