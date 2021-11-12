class WorkflowsController < ApplicationController
  
  include Seek::IndexPager

  include Seek::AssetsCommon

  before_action :workflows_enabled?
  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, except: [:index, :new, :create, :preview, :update_annotations_ajax]
  before_action :find_display_asset, only: [:show, :download, :diagram, :ro_crate]
  before_action :login_required, only: [:create, :create_version, :new_version, :create_content_blob, :create_ro_crate, :create_metadata, :metadata_extraction_ajax, :provide_metadata]

  include Seek::Publishing::PublishingCommon

  include Seek::Doi::Minting

  include Seek::IsaGraphExtensions
  include RoCrateHandling

  api_actions :index, :show, :create, :update, :destroy, :ro_crate

  rescue_from WorkflowDiagram::UnsupportedFormat do
    head :not_acceptable
  end

  def new_version
    respond_to do |format|
      format.html
    end
  end

  def create_version
    if params[:ro_crate]
      handle_ro_crate_post(true)
    else
      if handle_upload_data(true)
        comments = params[:revision_comments]
        respond_to do |format|
          if @workflow.save_as_new_version(comments)

            flash[:notice]="New version uploaded - now on version #{@workflow.version}"
          else
            flash[:error]="Unable to save new version"
          end
          format.html {redirect_to @workflow }
        end
      else
        flash[:error] = flash.now[:error]
        redirect_to @workflow
      end
    end
  end

  # PUT /Workflows/1
  def update
    update_annotations(params[:tag_list], @workflow) if params.key?(:tag_list)
    update_sharing_policies @workflow
    update_relationships(@workflow,params)

    respond_to do |format|
      if @workflow.update_attributes(workflow_params)
        flash[:notice] = "#{t('workflow')} metadata was successfully updated."
        format.html { redirect_to workflow_path(@workflow) }
        format.json { render json: @workflow, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@workflow), status: :unprocessable_entity }
      end
    end
  end

  def clear_session_info
    session.delete(:uploaded_content_blob_id)
    session.delete(:metadata)
    session.delete(:workflow_id)
    session.delete(:revision_comments)
  end

  def create_content_blob
    clear_session_info
    # This Workflow instance is just to make `handle_upload_data` work. It is not persisted beyond this action.
    @workflow = Workflow.new(workflow_class_id: params[:workflow_class_id])
    respond_to do |format|
      if handle_upload_data && @workflow.content_blob.save
        session[:uploaded_content_blob_id] = @workflow.content_blob.id
        session[:workflow_id] = params[:workflow_id]
        session[:revision_comments] = params[:revision_comments]
        format.html
      else
        format.html { render action: :new, status: :unprocessable_entity }
      end
    end
  end

  def create_ro_crate
    clear_session_info
    # This Workflow instance is just to make `handle_upload_data` work. It is not persisted beyond this action.
    @workflow = Workflow.new(workflow_class_id: params[:workflow_class_id])
    @crate_builder = WorkflowCrateBuilder.new(ro_crate_params)
    @crate_builder.workflow_class = @workflow.workflow_class
    blob_params = @crate_builder.build
    content_blob = @workflow.build_content_blob(blob_params)

    respond_to do |format|
      if blob_params && content_blob.save
        session[:uploaded_content_blob_id] = content_blob.id
        session[:workflow_id] = params[:workflow_id]
        session[:revision_comments] = params[:revision_comments]
        format.html { render action: :create_content_blob }
      else
        format.html { render action: :new, status: :unprocessable_entity }
      end
    end
  end

  # AJAX call to trigger metadata extraction, and pre-populate the associated @workflow
  def metadata_extraction_ajax
    session[:metadata] = { workflow_class_id: params[:workflow_class_id] }
    critical_error_msg = nil

    begin
      if params[:content_blob_id] == session[:uploaded_content_blob_id].to_s
        content_blob = ContentBlob.find_by_id(params[:content_blob_id])
        # This Workflow instance is just to get the extractor. It is not persisted beyond this action.
        workflow = Workflow.new(workflow_class_id: params[:workflow_class_id], content_blob: content_blob)
        extractor = workflow.extractor
        retrieve_content content_blob # Hack
        session[:metadata] = session[:metadata].merge(extractor.metadata)
      else
        critical_error_msg = "The file that was requested to be processed doesn't match that which had been uploaded."
      end
    rescue StandardError => e
      raise e unless Rails.env.production?
      Seek::Errors::ExceptionForwarder.send_notification(e, data: {
          message: "Problem attempting to extract metadata for content blob #{params[:content_blob_id]}" })
      critical_error_msg = 'An unexpected error occurred whilst extracting workflow metadata.'
    end

    respond_to do |format|
      if critical_error_msg
        format.js { render plain: critical_error_msg, status: :unprocessable_entity }
      else
        format.js { render plain: 'done', status: :ok }
      end
    end
  end

  # Displays the form Wizard for providing the metadata for the workflow
  def provide_metadata
    metadata = session[:metadata]
    @warnings ||= metadata.delete(:warnings) || []
    @errors ||= metadata.delete(:errors) || []
    if session[:workflow_id].present?
      @workflow = Workflow.find(session[:workflow_id])
      @workflow.assign_attributes(metadata)
    else
      @workflow ||= Workflow.new(metadata)
    end

    respond_to do |format|
      format.html
    end
  end

  # Receives the submitted metadata and registers the workflow
  def create_metadata
    @workflow = Workflow.new(workflow_params)
    update_sharing_policies(@workflow)
    filter_associated_projects(@workflow)

    # check the content blob id matches that previously uploaded and recorded on the session
    uploaded_blob_matches = (params[:content_blob_id].to_s == session[:uploaded_content_blob_id].to_s)
    @workflow.errors.add(:base, "The file uploaded doesn't match") unless uploaded_blob_matches

    #associate the content blob with the workflow
    blob = ContentBlob.find(params[:content_blob_id])
    @workflow.content_blob = blob
    update_annotations(params[:tag_list], @workflow) if params.key?(:tag_list)

    if uploaded_blob_matches && @workflow.save && blob.save
      update_relationships(@workflow, params)

      clear_session_info

      respond_to do |format|
        flash[:notice] = "#{t('workflow')} was successfully uploaded and saved." if flash.now[:notice].nil?

        format.html { redirect_to workflow_path(@workflow) }
        format.json { render json: @workflow }
      end
    else
      respond_to do |format|
        format.html do
          render :provide_metadata, status: :unprocessable_entity
        end
      end
    end
  end

  def create_version_metadata
    @workflow = Workflow.find(params[:id])
    @workflow.assign_attributes(workflow_params)
    update_sharing_policies(@workflow)
    filter_associated_projects(@workflow)

    # check the content blob id matches that previously uploaded and recorded on the session
    uploaded_blob_matches = (params[:content_blob_id].to_s == session[:uploaded_content_blob_id].to_s)
    @workflow.errors.add(:base, "The file uploaded doesn't match") unless uploaded_blob_matches

    #associate the content blob with the workflow
    blob = ContentBlob.find(params[:content_blob_id])
    new_version = @workflow.version += 1
    old_content_blob = @workflow.content_blob
    blob.asset_version = new_version
    @workflow.content_blob = blob
    # asset_id on the previous content blob gets blanked out after the above command is run, so need to do:
    old_content_blob.update_column(:asset_id, @workflow.id) if old_content_blob
    update_annotations(params[:tag_list], @workflow) if params.key?(:tag_list)

    if uploaded_blob_matches && @workflow.save_as_new_version(session[:revision_comments]) && blob.save
      update_relationships(@workflow, params)

      clear_session_info

      respond_to do |format|
        flash[:notice] = "#{t('workflow')} was successfully uploaded and saved." if flash.now[:notice].nil?

        format.html { redirect_to workflow_path(@workflow) }
        format.json { render json: @workflow }
      end
    else
      respond_to do |format|
        format.html do
          render :provide_metadata, status: :unprocessable_entity
        end
      end
    end
  end

  def diagram
    diagram_format = params.key?(:diagram_format) ? params[:diagram_format] : @workflow.default_diagram_format
    @diagram = @display_workflow.diagram(diagram_format)
    response.set_header('Content-Security-Policy', "default-src 'self'")
    respond_to do |format|
      format.html do
        if @diagram
          send_file(@diagram.path,
                    filename: @diagram.filename,
                    type: @diagram.content_type,
                    disposition: 'inline')
        else
          head :not_found
        end
      end
    end
  end

  def download
    ro_crate
  end

  def ro_crate
    send_ro_crate(@display_workflow.ro_crate_zip,
                  "workflow-#{@workflow.id}-#{@display_workflow.version}.crate.zip")
  end

  def create
    if params[:ro_crate]
      handle_ro_crate_post
    else
      super
    end
  end

  private

  def handle_ro_crate_post(new_version = false)
    @workflow = Workflow.new unless new_version
    extractor = Seek::WorkflowExtractors::ROCrate.new(params[:ro_crate])

    @workflow.assign_attributes(extractor.metadata.except(:errors, :warnings))
    @workflow.assign_attributes(workflow_params)
    crate_upload = params[:ro_crate]
    old_content_blob = new_version ? @workflow.content_blob : nil
    version = new_version ? @workflow.version + 1 : 1
    @workflow.build_content_blob(tmp_io_object: crate_upload,
                                 original_filename: crate_upload.original_filename,
                                 content_type: crate_upload.content_type,
                                 asset_version: version)
    if old_content_blob
      old_content_blob.update_column(:asset_id, @workflow.id)
    end

    if new_version
      success = @workflow.save_as_new_version(params[:revision_comments])
    else
      create_asset(@workflow)
      success = @workflow.save
    end

    if success
      render json: @workflow, include: json_api_include_param
    else
      render json: json_api_errors(@workflow), status: :unprocessable_entity
    end
  end

  def retrieve_content(blob)
    if !blob.file_exists?
      blob.remote_content_fetch_task&.cancel
      blob.retrieve
    end
  end

  def workflow_params
    params.require(:workflow).permit(:title, :description, :workflow_class_id, # :metadata,
                                     { project_ids: [] }, :license,
                                     { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                     { assay_assets_attributes: [:assay_id] }, { scales: [] },
                                     { publication_ids: [] }, :internals, :maturity_level, :source_link_url,
                                     :edam_topics, :edam_operations,
                                     { discussion_links_attributes: [:id, :url, :label, :_destroy] },
                                     *creator_related_params)
  end

  alias_method :asset_params, :workflow_params

  def ro_crate_params
    params.require(:ro_crate).permit({ workflow: [:data, :data_url, :make_local_copy] },
                                     { abstract_cwl: [:data, :data_url, :make_local_copy] },
                                     { diagram: [:data, :data_url, :make_local_copy] })
  end
end
