module Seek
  module DataciteDoi
    def self.included(base)
      base.before_filter :set_asset_version, :only=>[:mint_doi_confirm,:mint_doi,:minted_doi,:new_version,:update]
      base.before_filter :mint_doi_auth, :only=>[:mint_doi_confirm,:mint_doi,:minted_doi]
      base.before_filter :set_doi, :only=>[:mint_doi]
      base.before_filter :new_version_auth, :only=>[:new_version]
      base.before_filter :unpublish_auth, :only=>[:update]
    end

    def mint_doi_confirm
      respond_to do |format|
        format.html { render :template => "datacite_doi/mint_doi_confirm"}
      end
    end

    def mint_doi
      respond_to do |format|
        if mint
          add_doi_to_asset_version
          add_log
          flash[:notice] = "The DOI is successfully generated: #{@doi}"
        end
        format.html { redirect_to polymorphic_path(@asset_version.parent, :version => @asset_version.version)}
      end
    end

    def minted_doi
      respond_to do |format|
        format.html { render :template => "datacite_doi/minted_doi" }
      end
    end

    def generate_metadata_xml hash=metadata_hash
      if hash
        xml = "<resource xmlns='http://datacite.org/schema/kernel-3'
          xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
          xsi:schemaLocation='http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd'>"
        metadata_in_xml = hash.to_xml(:skip_types => true, :skip_instruct => true)
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
      unless @asset_version.parent.is_doiable?(@asset_version.version)
        error("Creating a DOI is not possible", "is invalid")
        return false
      end
    end

    def mint
      username = Seek::Config.datacite_username
      password = Seek::Config.datacite_password_decrypt
      url = Seek::Config.datacite_url.blank? ? nil : Seek::Config.datacite_url
      endpoint = Datacite.new(username, password, url)

      metadata_xml = generate_metadata_xml
      upload_response = endpoint.upload_metadata metadata_xml
      return false unless validate_response(upload_response)

      url = asset_url
      mint_response = endpoint.mint(@doi, url)
      return false unless validate_response(mint_response)
      true
    end

    def validate_response response
      if response.include?('OK')
        true
      else
        flash[:error] = "There is a problem working with DataCite Metadata Store service: #{response}"
        false
      end
    end

    def concat_attribute_to(node, attribute, value, xml)
      doc = Nokogiri::XML(xml)
      doc.xpath("//#{node}").select do |node|
        node["#{attribute}"] = value
        node
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
      base_host_url = "#{Seek::Config.site_base_host}"
      relative_url = "#{controller_name}/#{@asset_version.parent.id}?version=#{@asset_version.version}"
      if base_host_url.end_with?('/')
        base_host_url + relative_url
      else
        base_host_url + '/' + relative_url
      end
    end

    def metadata_hash
      creators = @asset_version.creators.collect{|creator| creator.last_name.capitalize + ', ' + creator.first_name.capitalize}
      uploader = @asset_version.contributor.try(:person)
      unless uploader.nil?
        creators << uploader.last_name.capitalize + ', ' + uploader.first_name.capitalize
      end
      {:identifier => @doi,
                       :creators => creators.uniq.collect{|creator| {:creatorName => creator}},
                       :titles => [@asset_version.title],
                       :publisher => Seek::Config.project_name,
                       :publicationYear => Time.now.year
      }
    end

    def set_doi
      asset = @asset_version.parent
      @doi = asset.generated_doi(@asset_version.version)
    end



    def add_doi_to_asset_version
      @asset_version.doi = @doi
      @asset_version.save
    end

    def add_log
      asset = @asset_version.parent
      AssetDoiLog.create(asset_type: asset.class.name, asset_id: asset.id, asset_version: @asset_version.version, doi: @doi, action: 1, user_id: current_user.id)
    end

    def new_version_auth
      asset = @asset_version.parent
      if asset.is_any_doi_minted?
        error("Uploading new version is not possible", "is invalid")
        return false
      end
    end

    def unpublish_auth
      asset = @asset_version.parent
      is_unpublish_request = asset.is_published? && params[:sharing] && params[:sharing][:sharing_scope].to_i != Policy::EVERYONE
      if  is_unpublish_request && asset.is_any_doi_minted?
        error("Un-publishing this asset is not possible", "is invalid")
        return false
      end
    end
  end
end