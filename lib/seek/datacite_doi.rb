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

    def mint_doi
      respond_to do |format|
        if metadata_validated?
          mint
          format.html { redirect_to :action => :minted_doi}
        else
          flash[:error] = "The mandatory fields (M) must be filled"
          format.html { render "datacite_doi/mint_doi_preview"}
        end
      end
    end

    def minted_doi
      respond_to do |format|
        format.html { render :template => "datacite_doi/minted"}
      end
    end

    def resolve_doi doi

    end

    def resolve_metadata doi

    end

    def upload_metadata metadata

    end

    def generate_metadata_in_xml metadata_param
      if metadata_param
        xml = "<resource xmlns='http://datacite.org/schema/kernel-3'
          xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
          xsi:schemaLocation='http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd'>"
        metadata_in_xml = metadata_param.to_xml
        metadata_in_xml.gsub!(/ type="array"/,'')
        xml << metadata_in_xml.split("<hash>")[1].split('</hash>').first
        xml << "</resource>"
        xml
      else
        nil
      end
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

    def metadata_validated?
      metadata = params[:metadata]
      if metadata
        identifier = metadata[:identifier]
        creators = metadata[:creators] ? metadata[:creators].collect{|creator| creator['creatorName']}.join('') : nil
        title = metadata[:titles] ? metadata[:titles].join('') : nil
        publisher = metadata[:publisher]
        publicationYear = metadata[:publicationYear]
        if identifier.blank? || creators.blank? || title.blank? || publisher.blank? || publicationYear.blank?
          validated = false
        else
          validated = true
        end
      else
        validated = false
      end
      validated
    end

    def mint
      username = Seek::Config.datacite_username
      password = Seek::Config.datacite_password
      url = Seek::Config.datacite_url.blank? ? nil : Seek::Config.datacite_url
      endpoint = Datacite.new(username, password, url)

      metadata = generate_metadata_in_xml params[:metadata]
      endpoint.upload_metadata metadata

      asset_url = "#{Rails.root}/#{controller_name}/#{@asset_version.parent.id}?version=#{@asset_version.version}"
      doi = params[:metadata][:identifier]
      endpoint.mint(doi, asset_url)
    end
  end
end