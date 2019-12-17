class WorkflowsController < ApplicationController
  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :workflows_enabled?
  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, except: [:index, :new, :create, :request_resource,:preview, :test_asset_url, :update_annotations_ajax]
  before_action :find_display_asset, only: [:show, :download, :diagram, :ro_crate]

  include Seek::Publishing::PublishingCommon
  include Seek::BreadCrumbs
  include Seek::Doi::Minting
  include Seek::IsaGraphExtensions

  rescue_from WorkflowDiagram::UnsupportedFormat do
    head :not_acceptable
  end

  def new_version
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

  # PUT /Workflows/1
  def update
    update_annotations(params[:tag_list], @workflow) if params.key?(:tag_list)
    update_sharing_policies @workflow
    update_relationships(@workflow,params)

    respond_to do |format|
      if @workflow.update_attributes(workflow_params)
        flash[:notice] = "#{t('Workflow')} metadata was successfully updated."
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
    session.delete(:processing_errors)
    session.delete(:processing_warnings)
  end

  def create_content_blob
    clear_session_info
    @workflow = Workflow.new(workflow_class_id: params[:workflow_class_id])
    respond_to do |format|
      if handle_upload_data && @workflow.content_blob.save
        session[:uploaded_content_blob_id] = @workflow.content_blob.id
        format.html
      else
        format.html { render action: :new }
      end
    end
  end

  def retrieve_content(blob)
    if !blob.file_exists?
      if (caching_job = blob.caching_job).exists?
        caching_job.first.destroy
      end
      blob.retrieve
    end
  end

  # AJAX call to trigger metadata extraction, and pre-populate the associated @workflow
  def metadata_extraction_ajax
    @workflow = Workflow.new(workflow_class_id: params[:workflow_class_id])
    session[:metadata] = {}
    critical_error_msg = nil

    begin
      if params[:content_blob_id] == session[:uploaded_content_blob_id].to_s
        @workflow.content_blob = ContentBlob.find_by_id(params[:content_blob_id])
        retrieve_content @workflow.content_blob
        metadata = @workflow.extractor.metadata
        errors = metadata.delete(:errors)
        warnings = metadata.delete(:warnings)
        session[:processing_errors] = errors if errors.any?
        session[:processing_warnings] = warnings if warnings.any?
        session[:metadata] = metadata
      else
        critical_error_msg = "The file that was requested to be processed doesn't match that which had been uploaded"
      end
    rescue StandardError => e
      raise e unless Rails.env.production?
      Seek::Errors::ExceptionForwarder.send_notification(e, data: {
          message: "Problem attempting to extract metadata for content blob #{params[:content_blob_id]}" })
      session[:processing_errors] = [e.message]
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
    @workflow ||= Workflow.new(session[:metadata].merge(workflow_class_id: params[:workflow_class_id]))
    @warnings ||= session[:processing_warnings] || []
    @errors ||= session[:processing_errors] || []

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

    if uploaded_blob_matches && @workflow.save && blob.save
      update_annotations(params[:tag_list], @workflow)
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
    respond_to do |format|
      format.html do
        send_file(@diagram.path,
                  filename: @diagram.filename,
                  type: @diagram.content_type,
                  disposition: 'inline')
      end
    end
  end

  def ro_crate
    crate = @display_workflow.ro_crate
    path = nil
    Tempfile.open('crate') do |f|
      path = f.path
      ROCrate::Writer.new(crate).write_zip(path)
    end
    respond_to do |format|
      format.html do
        send_file(path,
                  filename: "workflow-#{@workflow.id}-#{@display_workflow.version}-ro-crate.zip",
                  type: 'application/zip',
                  disposition: 'inline')
      end
    end
  end

  private

  def workflow_params
    params.require(:workflow).permit(:title, :description, :workflow_class_id, # :metadata,
                                     { project_ids: [] }, :license, :other_creators,
                                     { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                     { creator_ids: [] }, { assay_assets_attributes: [:assay_id] }, { scales: [] },
                                     { publication_ids: [] }, :internals)
  end

  alias_method :asset_params, :workflow_params
end
