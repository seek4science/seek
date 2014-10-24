require 'seek/annotation_common'

module Seek
  module AssetsCommon

    include Seek::AnnotationCommon
    include Seek::ContentBlobCommon
    include Seek::UploadHandling::DataUpload
    include Seek::DownloadHandling::DataDownload

    def find_display_asset asset=eval("@#{self.controller_name.singularize}");
      name = asset.class.name.underscore
      if asset
          #if no version is specified, show the latest version
          #otherwise, show the specified version, if (this version is correct for login and project member user or if (this is the latest version and the user doesn't login or is not project member')
          if params[:version]
            if asset.find_version(params[:version]).blank? || (!(User.logged_in_and_member?) && params[:version].to_i != asset.latest_version.version)
              error('This version is not available', "invalid route")
              return false
            else
              eval "@display_#{name} = asset.find_version(params[:version])"
            end
          else
            eval "@display_#{name} = asset.latest_version"
          end
        end
    end

    def update_relationships asset,params
      Relationship.create_or_update_attributions(asset, params[:attributions])

      # update related publications
      if params[:related_publication_ids]
        Relationship.create_or_update_attributions(asset, params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first] }, Relationship::RELATED_TO_PUBLICATION)
      end

      #Add creators
      AssetsCreator.add_or_update_creator_list(asset, params[:creators])
    end

    def update_assay_assets(asset,assay_ids,relationship_type_titles=nil)
      assay_ids ||= []
      relationship_type_titles ||= Array.new(assay_ids.size)
      assay_ids.each.with_index do |assay_id,index|
        assay = Assay.find(assay_id)
        if assay.can_edit?
          relationship = RelationshipType.find_by_title(relationship_type_titles[index])
          assay.relate(asset,relationship)
        end
      end

      #Destroy AssayAssets that aren't needed
      asset.assay_assets.each do |assay_asset|
        if assay_asset.assay.can_edit? and !assay_ids.include?(assay_asset.assay_id.to_s)
          AssayAsset.destroy(assay_asset.id)
        end
      end
    end

    def request_resource
      resource = self.controller_name.classify.find(params[:id])
      details = params[:details]

      Mailer.request_resource(current_user,resource,details,base_host).deliver

      render :update do |page|
        html = "An email has been sent on your behalf to <b>#{resource.managers.collect{|m| m.name}.join(", ")}</b> requesting the file <b>#{h(resource.title)}</b>."
        page[:requesting_resource_status].replace_html(html)
      end
    end

    def destroy_version
      name = self.controller_name.singularize
      @asset = eval("@#{name}")
      if Seek::Config.delete_asset_version_enabled
        @asset.destroy_version  params[:version]
        flash[:notice] = "Version #{params[:version]} was deleted!"
      else
        flash[:error] = "Deleting a version of #{@asset.class.name.underscore.humanize} is not enabled!"
      end
      respond_to do |format|
        format.html { redirect_to(polymorphic_path(@asset)) }
        format.xml { head :ok }
      end
    end

  end
end
