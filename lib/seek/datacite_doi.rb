module Seek
  module DataciteDoi
    def self.included(base)
      base.before_filter :set_asset_version
      base.before_filter :mint_doi_auth
      base.after_filter :log_minting_doi, :only=>[:mint]
    end

    def mint_doi_preview
      respond_to do |format|
        format.html { render :template => "datacite_doi/mint_doi_preview"}
      end
    end

    def mint

    end

    def minted

    end

    def resolve_doi doi

    end

    def resolve_metadata doi

    end

    def upload_metadata metadata

    end

    private

    def set_asset_version
      begin
        asset = self.controller_name.classify.constantize.find(params[:id])
        if params[:version]
          #find version
          #TODO @asset_version could be nil
          @asset_version = asset.find_version(params[:version].to_i)
        else
          @asset_version = asset.latest_version
        end
      rescue ActiveRecord::RecordNotFound
        error("This resource is not found","not found resource")
      end
    end

    def mint_doi_auth
      #is_published && can_manage
    end

    def log_minting_doi

    end
  end
end