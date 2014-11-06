module Seek
  module DataciteDoi
    def self.included(base)
      base.before_filter :set_asset
      base.before_filter :mint_doi_auth
      base.after_filter :log_minting_doi, :only=>[:mint]
    end

    def mint_doi_preview

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

    def set_asset
      #with version
    end

    def mint_doi_auth
      #is_published && can_manage
    end

    def log_minting_doi

    end
  end
end