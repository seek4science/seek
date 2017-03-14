module Seek
  module DataciteDoi
    include Seek::ExternalServiceWrapper

    def self.included(base)
      base.before_filter :set_asset_version, only: [:mint_doi_confirm, :mint_doi, :minted_doi, :new_version, :update]
      base.before_filter :mint_doi_auth, only: [:mint_doi_confirm, :mint_doi]
      base.before_filter :new_version_auth, only: [:new_version]
      base.before_filter :unpublish_auth, only: [:update]
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
      asset = controller_name.classify.constantize.find(params[:id])
      if params[:version]
        # find version
        # TODO @asset_version could be nil
        @asset_version = asset.find_version(params[:version].to_i)
      else
        @asset_version = asset.latest_version
      end
    rescue ActiveRecord::RecordNotFound
      error('This resource is not found', 'not found resource')
    end

    def mint_doi_auth
      unless @asset_version.parent.is_doiable?(@asset_version.version)
        error('Creating a DOI is not possible', 'is invalid')
        return false
      end
    end

    def new_version_auth
      asset = @asset_version.parent
      if asset.is_any_doi_minted?
        error('Uploading new version is not possible', 'is invalid')
        return false
      end
    end

    def unpublish_auth
      asset = @asset_version.parent
      is_unpublish_request = asset.is_published? && params[:policy_attributes] && params[:policy_attributes][:access_type].to_i != Policy::NO_ACCESS
      if is_unpublish_request && asset.is_any_doi_minted?
        error('Un-publishing this asset is not possible', 'is invalid')
        return false
      end
    end
  end
end
