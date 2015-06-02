require 'seek/annotation_common'

module Seek
  module AssetsCommon
    include Seek::AnnotationCommon
    include Seek::ContentBlobCommon
    include Seek::UploadHandling::DataUpload
    include Seek::DownloadHandling::DataDownload
    include Seek::PreviewHandling
    include Seek::DestroyHandling

    def new
      item=class_for_controller_name.new
      item.parent_name = params[:parent_name] if item.respond_to?(:parent_name)
      item.is_with_sample = params[:is_with_sample] if item.respond_to?(:is_with_sample)
      set_shared_item_variable(item)
      @content_blob = ContentBlob.new
      @page_title = params[:page_title]
      respond_to do |format|
        if User.logged_in_and_member?
          format.html # new.html.erb
        else
          flash[:error] = "You are not authorized to upload a new #{t(item.class.name.underscore)}. Only members of known projects, institutions or work groups are allowed to create new content."
          format.html { redirect_to eval("#{controller_name}_path") }
        end
      end
    end

    def edit

    end

    def create
      if handle_upload_data
        item = class_for_controller_name.new(params[controller_name.singularize.to_sym])
        create_asset_and_respond(item)
      else
        handle_upload_data_failure
      end
    end

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
          assay.associate(asset, relationship)
        end
      end
    end

    def request_resource
      resource = class_for_controller_name.find(params[:id])
      details = params[:details]
      mail = Mailer.request_resource(current_user, resource, details, base_host)
      mail.deliver

      render :update do |page|
        html = "An email has been sent on your behalf to <b>#{resource.managers_names}</b> requesting the file <b>#{h(resource.title)}</b>."
        page[:requesting_resource_status].replace_html(html)
      end
    end

    #i.e. Model, or DataFile according to the controller name
    def class_for_controller_name
      controller_name.classify.constantize
    end

    #i.e. @model = item, or @data_file = item - according to the item class name
    def set_shared_item_variable(item)
      eval("@#{item.class.name.underscore}=item")
    end

    # the standard response block after created a new asset
    def create_asset_and_respond(item)
      set_shared_item_variable(item)
      item.policy.set_attributes_with_sharing params[:sharing], item.projects
      update_annotations(params[:tag_list], item)
      update_scales item
      build_model_image item, params[:model_image] if item.is_a?(Model)

      if item.save
        create_content_blobs
        update_relationships(item, params)
        update_assay_assets(item, params[:assay_ids])
        unless return_to_fancy_parent(item)
          flash[:notice] = "#{t(item.class.name.underscore)} was successfully uploaded and saved."
          respond_to do |format|
            format.html { redirect_to item }
          end
        end
      else
        respond_to do |format|
          format.html do
            render action: 'new'
          end
        end
      end
    end

    def return_to_fancy_parent(item)
      return false unless item.respond_to?(:parent_name) && !item.parent_name.blank?
      render partial: 'assets/back_to_fancy_parent', locals: { child: item, parent_name: item.parent_name }
      true
    end

    def destroy_version
      asset = determine_asset_from_controller
      if Seek::Config.delete_asset_version_enabled
        asset.destroy_version params[:version]
        flash[:notice] = "Version #{params[:version]} was deleted!"
      else
        flash[:error] = "Deleting a version of #{asset.class.name.underscore.humanize} is not enabled!"
      end
      respond_to do |format|
        format.html { redirect_to(polymorphic_path(asset)) }
        format.xml { head :ok }
      end
    end

    # For use in autocompleters
    def typeahead
      model_name = controller_name.classify
      model_class = class_for_controller_name

      results = model_class.authorize_asset_collection(model_class.where('title LIKE ?', "#{params[:query]}%"), 'view')
      items = results.first(params[:limit] || 10).map do |item|
        contributor_name = item.contributor.person.name
        { id: item.id, name: item.title, hint: contributor_name, type: model_name, contributor: contributor_name }
      end

      respond_to do |format|
        format.json { render json: items.to_json }
      end
    end
  end
end
