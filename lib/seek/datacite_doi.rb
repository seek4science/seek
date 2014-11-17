module Seek
  module DataciteDoi
    def self.included(base)
      base.before_filter :set_asset_version
      base.before_filter :mint_doi_auth
      base.after_filter :log_minting_doi, :only=>[:mint_doi]
    end

    def mint_doi_preview
      respond_to do |format|
        format.html { render :template => "datacite_doi/mint_doi_preview"}
      end
    end

    def mint_doi
      respond_to do |format|
        if metadata_validated?
          if mint
            format.html { redirect_to :action => :minted_doi,
                                      :doi => params[:metadata][:identifier],
                                      :url => asset_url}
          else
            format.html { render "datacite_doi/mint_doi_preview"}
          end
        else
          flash[:error] = "The mandatory fields (M) must be filled"
          format.html { render "datacite_doi/mint_doi_preview", :status => :bad_request}
        end
      end
    end

    def minted_doi
      respond_to do |format|
        format.html { render :template => "datacite_doi/minted_doi" }
      end
    end

    def generate_metadata_in_xml metadata_param
      if metadata_param
        xml = "<resource xmlns='http://datacite.org/schema/kernel-3'
          xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
          xsi:schemaLocation='http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd'>"
        metadata_in_xml = metadata_param.to_xml(:skip_types => true, :skip_instruct => true)
        modified_xml = remove_empty_nodes(metadata_in_xml)
        modified_xml = concat_attribute_to('identifier', 'identifierType', 'DOI', modified_xml)
        modified_xml = concat_attribute_to('resourceType', 'resourceTypeGeneral', 'Dataset', modified_xml)
        modified_xml = concat_attribute_to('description', 'descriptionType', 'Abstract', modified_xml)
        xml << modified_xml.split("<hash>")[1].split('</hash>').first
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
      password = Seek::Config.datacite_password_decrypt
      url = Seek::Config.datacite_url.blank? ? nil : Seek::Config.datacite_url
      endpoint = Datacite.new(username, password, url)

      metadata = generate_metadata_in_xml params[:metadata]
      upload_response = endpoint.upload_metadata metadata
      return false unless validate_response(upload_response)

      url = asset_url
      doi = params[:metadata][:identifier]
      mint_response = endpoint.mint(doi, url)
      return false unless validate_response(mint_response)
      true
    end

    def validate_response response
      if response.include?('OK')
        true
      else
        flash.now[:error] = "There is a problem working with DataCite Metadata Store service: #{response}"
        false
      end
    end

    def concat_attribute_to(node, attribute, value, xml)
      doc = Nokogiri::XML(xml)
      doc.xpath("//#{node}").select do |n|
        n["#{attribute}"] = value
        n
      end
      doc.to_xml
    end

    def remove_empty_nodes xml
      doc = Nokogiri::XML(xml)
      doc.xpath("//*").each do |n|
        n.text.blank? ? n.remove : n
      end
      doc.to_xml
    end

    def asset_url
      "#{root_url}#{controller_name}/#{@asset_version.parent.id}?version=#{@asset_version.version}"
    end
  end
end