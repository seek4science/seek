module Seek
  # The standard basic actions for assets - currently show, new, create, edit, destroy. THe intention is to support all methods for all asset types.
  # DataFile is currently not fully supported due to biosample complications which are intended to be revisited.
  module AssetsStandardControllerActions
    include Seek::DestroyHandling
    include Seek::UploadHandling::DataUpload

    def new
      setup_new_asset
      respond_for_new
    end

    def show
      asset = resource_for_controller

      asset_version = find_display_asset asset
      respond_to do |format|
        format.html { render(params[:only_content] ? { layout: false } : {})}
        format.xml
        format.rdf { render template: 'rdf/show' }
        format.json { render json: asset, scope: { requested_version: asset_version }, include: json_api_include_param }
        format.datacite_xml { render xml: asset_version.datacite_metadata.to_s } if asset_version.respond_to?(:datacite_metadata)
        format.jsonld { render json: Seek::BioSchema::Serializer.new(asset_version).json_representation, adapter: :attributes } if asset_version.respond_to?(:to_schema_ld)
      end
    end

    def explore
      asset = resource_for_controller
      #drop invalid explore params
      [:page_rows, :page, :sheet].each do |param|
        if params[param].present? && (params[param] =~ /\A\d+\Z/).nil?
          params.delete(param)
        end
      end
      @display_asset = instance_variable_get("@display_#{asset.class.name.underscore}")
      if @display_asset.contains_extractable_spreadsheet?
        begin
          @workbook = Rails.cache.fetch("spreadsheet-workbook-#{@display_asset.content_blob.cache_key}") do
            @display_asset.spreadsheet
          end
          respond_to do |format|
            format.html
          end
        rescue SysMODB::SpreadsheetExtractionException
          respond_to do |format|
            flash[:error] = "There was an error when processing the #{t(asset.class.name.underscore)} to explore, perhaps it isn't a valid Excel spreadsheet"
            format.html { redirect_to polymorphic_path(asset, version: @display_asset.version) }
          end
        end
      else
        respond_to do |format|
          flash[:error] = "Unable to explore contents of this #{t(asset.class.name.underscore)}"
          format.html { redirect_to polymorphic_path(asset, version: @display_asset.version) }
        end
      end
    end

    def setup_new_asset
      attr={}
      if params["#{controller_name.singularize}"]
        attr = send("#{controller_name.singularize}_params")
      end
      item = class_for_controller_name.new(attr)

      # filter out any non editable associated assays
      item.assay_assets = item.assay_assets.select{|aa| aa.assay&.can_edit?} if item.respond_to?(:assay_assets)

      item.parent_name = params[:parent_name] if item.respond_to?(:parent_name)
      set_shared_item_variable(item)
      @content_blob = ContentBlob.new
      @page_title = params[:page_title]
      item
    end

    def respond_for_new
      respond_to do |format|
        if User.logged_in_and_member?
          format.html # new.html.erb
        else
          flash[:error] = "You are not authorized to upload a new #{t(controller_name.singularize)}. Only members of #{t('project').downcase.pluralize} are allowed to create content."
          format.html { redirect_to polymorphic_path(controller_name) }
        end
      end
    end

    # handles update for manage properties, the action for the manage form
    def manage_update
      item = resource_for_controller
      raise 'shouldnt get this far without manage rights' unless item.can_manage?
      item.update(params_for_controller)
      update_sharing_policies item
      respond_to do |format|
        if item.save
          flash[:notice] = "#{t(item.class.name.underscore)} was successfully updated."
          format.html { redirect_to(item) }
          format.json { render json: item, include: json_api_include_param }
        else
          format.html { render action: 'manage' }
          format.json { render json: json_api_errors(item), status: :unprocessable_entity }
        end
      end
    end

    def edit; end

    def manage; end

    def create
      item = initialize_asset

      if item.is_git_versioned? || handle_upload_data
        create_asset_and_respond(item)
      else
        handle_upload_data_failure
      end
    end

    # i.e. Model, or DataFile according to the controller name
    def class_for_controller_name
      controller_model
    end

    # i.e. @model = item, or @data_file = item - according to the item class name
    def set_shared_item_variable(item)
      instance_variable_set("@#{item.class.name.underscore}", item)
    end

    # the standard response block after created a new asset
    def create_asset_and_respond(item)
      item = create_asset(item)
      if item.save
        unless return_to_fancy_parent(item)
          flash[:notice] = "#{t(item.class.name.underscore)} was successfully uploaded and saved."
          respond_to do |format|
            format.html { redirect_to params[:single_page] ?
              { controller: :single_pages, action: :show, id: params[:single_page] } 
              : item }
            format.json { render json: item, include: json_api_include_param }
          end
        end
      else
        respond_to do |format|
          format.html { render action: 'new' }
          format.json { render json: json_api_errors(item), status: :unprocessable_entity }
        end
      end
    end

    # makes sure the asset it only associated with projects that match the current user
    def filter_associated_projects(asset, user = User.current_user)
      asset.projects = asset.projects & user.person.projects
    end

    def update_sharing_policies(item, parameters = params)
      item.policy.set_attributes_with_sharing(policy_params(parameters)) if policy_params(parameters).present?
    end

    def update_linked_custom_metadatas(item, parameters = params)

      root_key = controller_name.singularize.to_sym

      # return no custom metdata is selected
      return unless params[root_key][:custom_metadata_attributes].present?
      return unless params[root_key][:custom_metadata_attributes][:custom_metadata_type_id].present?
      item.custom_metadata.update_linked_custom_metadata(parameters[root_key][:custom_metadata_attributes])

    end

    def initialize_asset
      item = class_for_controller_name.new(asset_params)
      set_shared_item_variable(item)

      item
    end

    def create_asset(item)
      update_sharing_policies item
      update_annotations(params[:tag_list], item)
      update_relationships(item, params)
      build_model_image item, model_image_params if item.is_a?(Model) && model_image_present?
      item
    end

    def edit_version
      item = class_for_controller_name.find(params[:id])
      version = item.standard_versions.find_by(version: params[:version])

      if version&.update(edit_version_params(version))
        flash[:notice] = "Version #{params[:version]} was successfully updated."
      else
        flash[:error] = "Unable to update version #{params[:version]}. Please try again."
      end
      redirect_to item
    end

    def return_to_fancy_parent(item)
      return false unless item.respond_to?(:parent_name) && !item.parent_name.blank?
      render partial: 'assets/back_to_fancy_parent', locals: { child: item, parent_name: item.parent_name }
      true
    end

    def edit_version_params(version)
      p = [:revision_comments]
      p << :visibility if version.can_change_visibility?
      params.permit(*p)
    end

    def json_api_include_param
      [params[:include]]
    end
  end
end
