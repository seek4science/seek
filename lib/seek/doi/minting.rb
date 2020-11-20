module Seek
  module Doi
    module Minting
      include Seek::ExternalServiceWrapper

      def self.included(base)
        base.before_action :set_asset_version, only: %i[mint_doi_confirm mint_doi minted_doi create_version update]
        base.before_action :mint_doi_auth, only: %i[mint_doi_confirm mint_doi]
        base.before_action :create_version_auth, only: [:create_version]
        base.before_action :unpublish_auth, only: [:update]
      end

      def mint_doi_confirm
        respond_to do |format|
          format.html { render template: 'datacite_doi/mint_doi_confirm' }
        end
      end

      def mint_doi
        version_path = polymorphic_path(@asset_version.parent, version: @asset_version.version)

        wrap_service('DataCite', version_path) do
          if @asset_version.mint_doi
            flash[:notice] = 'DOI successfully minted'
          else
            flash[:error] = @snapshot.errors.full_messages
          end

          redirect_to version_path
        end
      end

      private

      def set_asset_version
        asset = controller_model.find(params[:id])
        @asset_version = if params[:version]
                           # find version
                           # TODO @asset_version could be nil
                           asset.find_version(params[:version].to_i)
                         else
                           asset.latest_version
                         end
      rescue ActiveRecord::RecordNotFound
        error('This resource is not found', 'not found resource')
      end

      def mint_doi_auth
        unless @asset_version.parent.can_manage?
          error('You are not authorized to create a DOI for this resource', 'is invalid')
          return false
        end
        unless @asset_version.parent.is_published?
          error('Cannot create a DOI for an unpublished resource', 'is invalid')
          return false
        end
        unless @asset_version.can_mint_doi?
          error('Creating a DOI is not possible', 'is invalid')
          return false
        end

        true
      end

      def create_version_auth
        asset = @asset_version.parent
        if asset.has_doi?
          error('Uploading new version is not possible', 'is invalid')
          return false
        end
      end

      def unpublish_auth
        asset = @asset_version.parent
        is_unpublish_request = asset.is_published? && params[:policy_attributes] && params[:policy_attributes][:access_type].to_i != Policy::NO_ACCESS
        if is_unpublish_request && asset.has_doi?
          error('Un-publishing this asset is not possible', 'is invalid')
          return false
        end
      end
    end
  end
end
