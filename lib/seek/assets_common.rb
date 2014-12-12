require 'seek/annotation_common'

module Seek
  module AssetsCommon

    include Seek::AnnotationCommon
    include Seek::ContentBlobCommon
    include Seek::UploadHandling::DataUpload
    include Seek::DownloadHandling::DataDownload
    include Seek::PreviewHandling
    include Seek::DestroyHandling

    def find_display_asset asset=eval("@#{self.controller_name.singularize}")
      requested_version = params[:version] || asset.latest_version.version
      found_version = asset.find_version(requested_version)
      if !found_version || anonymous_request_for_previous_version?(asset, requested_version)
        error('This version is not available', "invalid route")
        return false
      else
        eval "@display_#{asset.class.name.underscore} = asset.find_version(found_version)"
      end
    end

    def anonymous_request_for_previous_version?(asset, requested_version)
      (!(User.logged_in_and_member?) && requested_version.to_i != asset.latest_version.version)
    end

    def update_relationships asset, params
      Relationship.create_or_update_attributions(asset, params[:attributions])

      # update related publications
      publication_params = (params[:related_publication_ids] || []).collect do |id|
        ["Publication", id.split(",").first]
      end
      Relationship.create_or_update_attributions(asset, publication_params, Relationship::RELATED_TO_PUBLICATION)

      #Add creators
      AssetsCreator.add_or_update_creator_list(asset, params[:creators])
    end

    def update_assay_assets(asset,assay_ids,relationship_type_titles=nil)
      assay_ids ||= []
      relationship_type_titles ||= Array.new(assay_ids.size)
      create_assay_assets(asset,assay_ids, relationship_type_titles)

      destroy_redundant_assay_assets(asset,assay_ids)
    end

    def destroy_redundant_assay_assets(asset,assay_ids)
      asset.assay_assets.each do |assay_asset|
        if assay_asset.assay.can_edit? && !assay_ids.include?(assay_asset.assay_id.to_s)
          AssayAsset.destroy(assay_asset.id)
        end
      end
    end

    def create_assay_assets(asset,assay_ids, relationship_type_titles)
      assay_ids.each.with_index do |assay_id, index|
        if (assay = Assay.find(assay_id)).can_edit?
          relationship = RelationshipType.find_by_title(relationship_type_titles[index])
          assay.relate(asset, relationship)
        end
      end
    end

    def request_resource
      resource = self.controller_name.classify.constantize.find(params[:id])
      details = params[:details]
      mail = Mailer.request_resource(current_user,resource,details,base_host)
      mail.deliver

      render :update do |page|
        html = "An email has been sent on your behalf to <b>#{resource.managers_names}</b> requesting the file <b>#{h(resource.title)}</b>."
        page[:requesting_resource_status].replace_html(html)
      end
    end

    def destroy_version
      asset = determine_asset_from_controller
      if Seek::Config.delete_asset_version_enabled
        asset.destroy_version  params[:version]
        flash[:notice] = "Version #{params[:version]} was deleted!"
      else
        flash[:error] = "Deleting a version of #{asset.class.name.underscore.humanize} is not enabled!"
      end
      respond_to do |format|
        format.html { redirect_to(polymorphic_path(asset)) }
        format.xml { head :ok }
      end
    end



  end
end
