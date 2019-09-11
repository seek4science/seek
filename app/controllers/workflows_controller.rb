class WorkflowsController < ApplicationController
  
  include Seek::IndexPager

  include Seek::AssetsCommon

  # before_action Seek::Config.workflows_enabled
  before_action :find_assets, :only => [ :index ]
  before_action :find_and_authorize_requested_item, :except => [ :index, :new, :create, :request_resource,:preview, :test_asset_url, :update_annotations_ajax]
  before_action :find_display_asset, :only=>[:show, :download]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs
  include Seek::Doi::Minting

  include Seek::IsaGraphExtensions

  def new_version
    if handle_upload_data(true)
      comments=params[:revision_comments]


      respond_to do |format|
        if @workflow.save_as_new_version(comments)

          flash[:notice]="New version uploaded - now on version #{@workflow.version}"
        else
          flash[:error]="Unable to save new version"          
        end
        format.html {redirect_to @workflow }
      end
    else
      flash[:error]=flash.now[:error] 
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
        format.json { render json: @workflow }
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@workflow), status: :unprocessable_entity }
      end
    end
  end

  def clear_session_info
    session.delete(:workflow_class_id)
    session.delete(:uploaded_content_blob_id)
    session.delete(:metadata)
    session.delete(:extraction_exception_message)
    session.delete(:processing_warnings)
  end

  def create_content_blob
    clear_session_info
    session[:fred] = 'bob'
    @workflow = Workflow.new
    session[:workflow_class_id] = params[:workflow_class_id]
     respond_to do |format|
      if handle_upload_data && @workflow.content_blob.save
        session[:uploaded_content_blob_id] = @workflow.content_blob.id
        format.html {}
      else
        session.delete(:uploaded_content_blob_id)
        format.html { render action: :new }
      end
    end
  end

  def retrieve_content (blob)
    if !blob.file_exists?
      if (caching_job = blob.caching_job).exists?
        caching_job.first.destroy
      end
      blob.retrieve
    end
  end

  # AJAX call to trigger metadata extraction, and pre-populate the associated @workflow
  def metadata_extraction_ajax
    @workflow = Workflow.new
    @warnings = nil
    critical_error_msg = nil
    session.delete :extraction_exception_message

    session[:metadata] = {}

    begin
      if params[:content_blob_id] == session[:uploaded_content_blob_id].to_s
        @workflow.content_blob = ContentBlob.find_by_id(params[:content_blob_id])
        retrieve_content @workflow.content_blob

        workflow_class = WorkflowClass.find_by_id (session[:workflow_class_id])
        metadata_name = "extract_#{workflow_class.key}_metadata"
        if defined? metadata_name
          self.send(metadata_name, @workflow)
        end
      else
        critical_error_msg = "The file that was requested to be processed doesn't match that which had been uploaded"
      end
    rescue Exception => e
      Seek::Errors::ExceptionForwarder.send_notification(e, data:{message: "Problem attempting to extract metadata for content blob #{params[:content_blob_id]}"})
      session[:extraction_exception_message] = e.message
    end

    session[:processing_warnings] = @warnings

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
    @workflow = Workflow.new()

    @warnings ||= session[:processing_warnings] || []
    @exception_message ||= session[:extraction_exception_message]

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
    all_valid = uploaded_blob_matches = (params[:content_blob_id].to_s == session[:uploaded_content_blob_id].to_s)

    #associate the content blob with the workflow
    blob = ContentBlob.find(params[:content_blob_id])
    @workflow.content_blob = blob

    # @workflow.workflow_class = WorkflowClass.find(session[:workflow_class_id])
#    @workflow.metadata = params[:metadata] FIX ME!!
    all_valid = @workflow.save && blob.save

    if all_valid

      workflow_version = Workflow::Version.find_by workflow_id: @workflow.id, version: @workflow.version
      workflow_version.workflow_class_id = session[:workflow_class_id]
      workflow_version.metadata = params[:metadata]
      workflow_version.save

      update_annotations(params[:tag_list], @workflow)

      update_relationships(@workflow, params)

      session.delete(:uploaded_content_blob_id)
      session.delete(:processed_workflow_id)
      session.delete(:processed_warnings)

      respond_to do |format|
        flash[:notice] = "#{t('workflow')} was successfully uploaded and saved." if flash.now[:notice].nil?

         format.html { redirect_to workflow_path(@workflow) }
        format.json { render json: @workflow }
      end

    else
      @workflow.errors.add(:base, "The file uploaded doesn't match") unless uploaded_blob_matches

      @workflow.valid? if uploaded_blob_matches

      respond_to do |format|
        format.html do
          render :provide_metadata, status: :unprocessable_entity
        end
      end
    end
  end



  private

  def workflow_params
    params.require(:workflow).permit(:title, :description, :workflow_class_id, # :metadata,
                                     { project_ids: [] }, :license, :other_creators,
                                { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                { creator_ids: [] }, { assay_assets_attributes: [:assay_id] }, { scales: [] },
                                { publication_ids: [] })
  end

  alias_method :asset_params, :workflow_params

  def extract_CWL_metadata(w)
   begin
      @content_blob = w.content_blob
      cwl_string = @content_blob.read
      cwl = YAML.load(cwl_string)
      if cwl.has_key? 'label'
        session[:metadata][:title] = cwl['label']
      else
        flash[:warning] = 'Unable to determine title of workflow'
      end
      if cwl.has_key? 'doc'
        session[:metadata][:description] = cwl['doc']
      end
    rescue Exception => e
      session[:extraction_exception_message] = e.message
    end

  end

  def extract_GALAXY_metadata(w)
    begin
      @content_blob = w.content_blob
      galaxy_string = @content_blob.read
      galaxy = JSON.parse(galaxy_string)
      if galaxy.has_key? "name"
        session[:metadata][:title] = galaxy["name"]
      else
        flash[:warning] = 'Unable to determine title of workflow'
      end
    rescue Exception => e
      session[:extraction_exception_message] = e.message
    end

  end

  def extract_KNIME_metadata(w)
    begin
      @content_blob = w.content_blob
      knime_string = @content_blob.read
      knime = LibXML::XML::Parser.string(knime_string).parse
      knime.root.namespaces.default_prefix = 'k'

      title = knime.find('/k:config/k:entry[not(@isnull="true")][@key="name"]/@value').first.value
      if !title.nil?
        session[:metadata][:title] = title.to_s
      else
        session[:metadata][:title] = "missing_title"
        flash[:warning] = 'Unable to determine title of workflow'
      end
      description = knime.find('/k:config/k:entry[not(@isnull="true")][@key="customDescription"]/@value').first.value
      if !description.nil?
        session[:metadata][:description] = description
      end
    rescue Exception => e
      session[:extraction_exception_message] = e.message
    end

  end

  def extract_RO_metadata(w)
    begin
      @content_blob = w.content_blob
      ro_string = @content_blob.read
      ro = JSON.parse(ro_string)
      if ro.has_key? "name"
        session[:metadata][:title] = ro["name"]
      else
        flash[:warning] = 'Unable to determine title of workflow'
      end
      if ro.has_key? "description"
        session[:metadata][:description] = ro["description"]
      end
    rescue Exception => e
      session[:extraction_exception_message] = e.message
    end

  end



end
