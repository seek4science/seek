require 'seek/annotation_common'

module Seek
  module AssetsCommon
    include Seek::AnnotationCommon
    include Seek::ContentBlobCommon
    include Seek::PreviewHandling
    include Seek::AssetsStandardControllerActions

    def find_display_asset(asset = eval("@#{controller_name.singularize}"))
      requested_version = params[:version] || asset.latest_version.version
      found_version = asset.find_version(requested_version)
      if !found_version || anonymous_request_for_previous_version?(asset, requested_version)
        error('This version is not available', 'invalid route')
        return false
      else
        eval "@display_#{asset.class.name.underscore} = asset.find_version(found_version)"
      end
    end

    def anonymous_request_for_previous_version?(asset, requested_version)
      (!(User.logged_in_and_member?) && requested_version.to_i != asset.latest_version.version)
    end

    def update_relationships(asset, params)
      Relationship.create_or_update_attributions(asset, params[:attributions])

      # update related publications
      publication_params = (params[:related_publication_ids] || []).collect do |id|
        ['Publication', id.split(',').first]
      end
      Relationship.create_or_update_attributions(asset, publication_params, Relationship::RELATED_TO_PUBLICATION)

      # Add creators
      AssetsCreator.add_or_update_creator_list(asset, params[:creators])
    end

    def update_assay_assets(asset, assay_ids, relationship_type_titles = nil)
      assay_ids ||= []
      relationship_type_titles ||= Array.new(assay_ids.size)
      create_assay_assets(asset, assay_ids, relationship_type_titles)

      destroy_redundant_assay_assets(asset, assay_ids)
    end

    def destroy_redundant_assay_assets(asset, assay_ids)
      asset.assay_assets.each do |assay_asset|
        if assay_asset.assay.can_edit? && !assay_ids.include?(assay_asset.assay_id.to_s)
          AssayAsset.destroy(assay_asset.id)
        end
      end
    end

    def create_assay_assets(asset, assay_ids, relationship_type_titles)
      assay_ids.each.with_index do |assay_id, index|
        if (assay = Assay.find(assay_id)).can_edit?
          relationship = RelationshipType.find_by_title(relationship_type_titles[index])
          assay.associate(asset, relationship: relationship)
        end
      end
    end

    def request_resource
      resource = class_for_controller_name.find(params[:id])
      details = params[:details]
      mail = Mailer.request_resource(current_user, resource, details)
      mail.deliver_now

      render :update do |page|
        html = "An email has been sent on your behalf to <b>#{resource.managers_names}</b> requesting the file <b>#{h(resource.title)}</b>."
        page[:requesting_resource_status].replace_html(html)
      end
    end

    # For use in autocompleters
    def typeahead
      model_name = controller_name.classify
      model_class = class_for_controller_name

      results = model_class.authorize_asset_collection(model_class.where('title LIKE ?', "#{params[:query]}%"), 'view')
      items = results.first(params[:limit] || 10).map do |item|
        contributor_name = item.contributor.try(:person).try(:name)
        { id: item.id, name: item.title, hint: contributor_name, type: model_name, contributor: contributor_name }
      end

      respond_to do |format|
        format.json { render json: items.to_json }
      end
    end
  end
end
