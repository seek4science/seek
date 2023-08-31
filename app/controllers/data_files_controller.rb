
require 'simple-spreadsheet-extractor'

class DataFilesController < ApplicationController

  include Seek::IndexPager
  include SysMODB::SpreadsheetExtractor
  include MimeTypesHelper

  include Seek::AssetsCommon

  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, except: [:index, :new, :create, :create_content_blob,
                                                             :preview, :update_annotations_ajax, :rightfield_extraction_ajax, :provide_metadata]
  before_action :find_display_asset, only: [:show, :explore, :download]
  before_action :get_sample_type, only: :extract_samples
  before_action :check_already_extracted, only: :extract_samples
  before_action :forbid_new_version_if_samples, :only => :create_version

  before_action :oauth_client, only: :retrieve_nels_sample_metadata
  before_action :nels_oauth_session, only: :retrieve_nels_sample_metadata
  before_action :rest_client, only: :retrieve_nels_sample_metadata

  before_action :login_required, only: [:create, :create_content_blob, :create_metadata, :rightfield_extraction_ajax, :provide_metadata]

  # has to come after the other filters
  include Seek::Publishing::PublishingCommon

  include Seek::Doi::Minting

  include Seek::IsaGraphExtensions

  api_actions :index, :show, :create, :update, :destroy

  def destroy
    if @data_file.extracted_samples.any? && !params[:destroy_extracted_samples]
      redirect_to destroy_samples_confirm_data_file_path(@data_file)
    else
      if params[:destroy_extracted_samples] == '1'
        @data_file.extracted_samples.destroy_all
      end
      super
    end
  end

  def destroy_samples_confirm
    if @data_file.can_delete?
      respond_to do |format|
        format.html
      end
    end
  end

  def create_version
    if handle_upload_data(true)
      comments = params[:revision_comments]

      respond_to do |format|
        if @data_file.save_as_new_version(comments)
          flash[:notice] = "New version uploaded - now on version #{@data_file.version}"
        else
          flash[:error] = 'Unable to save newflash[:error] version'
        end
        format.html { redirect_to @data_file }
        format.json { render json: @data_file, include: [params[:include]]}
      end
    else
      flash[:error] = flash.now[:error]
      redirect_to @data_file
    end
  end

  def create
    @data_file = DataFile.new(data_file_params)

    if handle_upload_data
      update_sharing_policies(@data_file)

      update_annotations(params[:tag_list], @data_file)
      update_relationships(@data_file, params)
      update_template() if params.key?(:file_template_id)

      if @data_file.save
        if !@data_file.parent_name.blank?
          render partial: 'assets/back_to_fancy_parent', locals: { child: @data_file, parent_name: @data_file.parent_name, is_not_fancy: true }
        else
          respond_to do |format|
            flash[:notice] = "#{t('data_file')} was successfully uploaded and saved." if flash.now[:notice].nil?
            format.html { redirect_to data_file_path(@data_file) }
            format.json { render json: @data_file, include: [params[:include]] }
          end
        end
      else
        respond_to do |format|
          format.html { render action: 'new' }
          format.json { render json: json_api_errors(@data_file), status: :unprocessable_entity }
        end
      end
    else
      handle_upload_data_failure
    end
  end

  def update
    update_annotations(params[:tag_list], @data_file) if params.key?(:tag_list)
    update_sharing_policies @data_file
    update_relationships(@data_file, params)
    update_template() if params.key?(:file_template_id)

    respond_to do |format|
      if @data_file.update(data_file_params)
        flash[:notice] = "#{t('data_file')} metadata was successfully updated."
        format.html { redirect_to data_file_path(@data_file) }
        format.json {render json: @data_file, include: [params[:include]]}
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@data_file), status: :unprocessable_entity }
      end
    end
  end

  def update_template
    if (params[:file_template_id].empty?)
      @data_file.file_template_id = nil
      ft = nil
    else
      @data_file.file_template_id = params[:file_template_id]
      ft = FileTemplate.find(params[:file_template_id])
    end
  end

  def filter
    scope = DataFile
    scope = scope.joins(:projects).where(projects: { id: current_user.person.projects }) unless (params[:all_projects] == 'true')
    scope = scope.where(simulation_data: true) if (params[:simulation_data] == 'true')
    scope = scope.with_extracted_samples if (params[:with_samples] == 'true')
    @data_files = scope.where('data_files.title LIKE ?', "%#{params[:filter]}%").distinct.authorized_for('view').first(20)

    respond_to do |format|
      format.html { render partial: 'data_files/association_preview', collection: @data_files, locals: { hide_sample_count: !params[:with_samples] } }
    end
  end

  def samples_table
    respond_to do |format|
      format.html do
        render(partial: 'samples/table_view', locals: {
                 samples: @data_file.extracted_samples.includes(:sample_type),
                 source_url: samples_table_data_file_path(@data_file)
               })
      end
      format.json { @samples = @data_file.extracted_samples.select([:id, :title, :json_metadata]) }
    end
  end

  def select_sample_type
    @possible_sample_types = @data_file.possible_sample_types

    respond_to do |format|
      format.html
    end
  end

  def extract_samples
    if params[:confirm]
      SampleDataPersistJob.new(@data_file, @sample_type, assay_ids: params["assay_ids"]).queue_job
      flash[:notice] = 'Started creating extracted samples'
    else
      SampleDataExtractionJob.new(@data_file, @sample_type).queue_job
    end

    respond_to do |format|
      format.html { redirect_to @data_file }
    end
  end

  def confirm_extraction
    @samples, @rejected_samples = Seek::Samples::Extractor.new(@data_file).fetch.partition(&:valid?)
    @sample_type = @samples.first.sample_type if @samples.any?
    @sample_type ||= @rejected_samples.first.sample_type if @rejected_samples.any?

    respond_to do |format|
      format.html
    end
  end

  def cancel_extraction
    Seek::Samples::Extractor.new(@data_file).clear

    respond_to do |format|
      flash[:notice] = 'Sample extraction cancelled'
      format.html { redirect_to @data_file }
    end
  end

  def extraction_status
    job_status = @data_file.sample_extraction_task.status

    respond_to do |format|
      format.html { render partial: 'data_files/sample_extraction_status', locals: { data_file: @data_file, job_status: job_status } }
    end
  end

  def persistence_status
    job_status = @data_file.sample_persistence_task.status

    respond_to do |format|
      format.html { render partial: 'data_files/sample_persistence_status', locals: { data_file: @data_file, job_status: job_status, previous_status: params[:previous_status] } }
    end
  end

  def retrieve_nels_sample_metadata
    begin
      if @data_file.content_blob.retrieve_from_nels(@oauth_session.access_token)
        @sample_type = @data_file.reload.possible_sample_types.last

        if @sample_type
          SampleDataExtractionJob.new(@data_file, @sample_type, overwrite: true).queue_job

          respond_to do |format|
            format.html { redirect_to @data_file }
          end
        else
          flash[:notice] = 'Successfully downloaded sample metadata from NeLS, but could not find a matching sample type.'

          respond_to do |format|
            format.html { redirect_to @data_file }
          end
        end
      else
        flash[:error] = 'Could not download sample metadata from NeLS.'

        respond_to do |format|
          format.html { redirect_to @data_file }
        end
      end
    rescue RestClient::Unauthorized
      redirect_to @oauth_client.authorize_url
    rescue RestClient::ResourceNotFound
      flash[:error] = 'No sample metadata available.'

      respond_to do |format|
        format.html { redirect_to @data_file }
      end
    end
  end

  ### ACTIONS RELATED TO DATA FILE UPLOAD AND RIGHTFIELD EXTRACTION ###

  # handles the uploading of the file to create a content blob, which is then associated with a new unsaved datafile
  # and stored on the session
  def create_content_blob
    # clean up the session
    session.delete(:uploaded_content_blob_id)
    session.delete(:processed_datafile)
    session.delete(:processed_assay)
    session.delete(:processed_warnings)

    @data_file = setup_new_asset
    respond_to do |format|
      if handle_upload_data && @data_file.content_blob.save
        session[:uploaded_content_blob_id] = @data_file.content_blob.id
        format.js
        format.html { {params: params[:single_page]} if params[:single_page] }
      else
        session.delete(:uploaded_content_blob_id)
        format.js
        format.html { render action: :new }
      end
    end
  end

  # AJAX call to trigger any RightField extraction (if appropriate), and pre-populates the associated @data_file and
  # @assay
  def rightfield_extraction_ajax
    @data_file = setup_new_asset
    @assay = Assay.new
    @warnings = nil
    critical_error_msg = nil
    session.delete :extraction_exception_message

    begin
      if params[:content_blob_id].to_s == session[:uploaded_content_blob_id].to_s
        @data_file.content_blob = ContentBlob.find_by_id(params[:content_blob_id])
        @warnings = @data_file.populate_metadata_from_template
        @assay, warnings = @data_file.initialise_assay_from_template
        @warnings.merge(warnings)
      else
        critical_error_msg = "The file that was requested to be processed doesn't match that which had been uploaded"
        notify_content_blob_mismatch(params[:content_blob_id], session[:uploaded_content_blob_id])
      end
    rescue Exception => e
      Seek::Errors::ExceptionForwarder.send_notification(e, data:{message: "Problem attempting to extract from RightField for content blob #{params[:content_blob_id]}"})
      session[:extraction_exception_message] = 'Rightfield extraction error'
    end

    session[:processed_datafile] = @data_file
    session[:processed_assay] = @assay
    session[:processing_warnings] = @warnings

    respond_to do |format|
      if critical_error_msg
        format.js { render plain: critical_error_msg, status: :unprocessable_entity }
      else
        format.js { render plain: 'done', status: :ok }
      end
    end
  end

  def notify_content_blob_mismatch(param_id, session_id)
    begin
      raise 'Content blob mismatch during data file creation'
    rescue RuntimeError => e
      Seek::Errors::ExceptionForwarder.send_notification(e, data:{
        message: "Parameter and Session Content Blob id don't match",
        param_blob_id: param_id.inspect,
        session_blob_id: session_id.inspect
      })
    end
  end

  # Displays the form Wizard for providing the metadata for both the data file, and possibly related Assay
  # if not already provided and available, it will use those that had previously been populated through RightField extraction
  def provide_metadata
    @data_file ||= session[:processed_datafile]
    @assay ||= session[:processed_assay]

    # this peculiar line avoids a no method error when calling super later on, when there are no assays in the database
    # this I believe is caused by accessing the unmarshalled @assay before the Assay class has been encountered. Adding this line
    # avoids the error
    Assay.new
    @warnings ||= session[:processing_warnings] || []
    @exception_message ||= session[:extraction_exception_message]
    @create_new_assay = @assay && @assay.new_record? && !@assay.title.blank?
    @data_file.assay_assets.build(assay_id: @assay.id) if @assay.persisted?

    respond_to do |format|
      format.js
      format.html
    end
  end

  # Receives the submitted metadata and registers the datafile and assay
  def create_metadata
    @data_file = DataFile.new(data_file_params)
    assay_params = data_file_assay_params
    sop_id = assay_params.delete(:sop_id)
    @create_new_assay = assay_params.delete(:create_assay)

    update_sharing_policies(@data_file)
    update_annotations(params[:tag_list], @data_file)

    @assay = Assay.new(assay_params)
    if sop_id
      sop = Sop.find_by_id(sop_id)
      @assay.sops << sop if sop && sop.can_view?
    end
    @assay.policy = @data_file.policy.deep_copy if @create_new_assay

    filter_associated_projects(@data_file)

    # check the content blob id matches that previously uploaded and recorded on the session
    all_valid = uploaded_blob_matches = (params[:content_blob_id].to_s == session[:uploaded_content_blob_id].to_s)

    unless uploaded_blob_matches
      notify_content_blob_mismatch(params[:content_blob_id], session[:uploaded_content_blob_id])
    end

    #associate the content blob with the data file
    blob = ContentBlob.find(params[:content_blob_id])
    @data_file.content_blob = blob

    # if creating a new assay, check it is valid and the associated study is editable
    all_valid = all_valid && !@create_new_assay || (@assay.study.try(:can_edit?) && @assay.save)

    update_template() if params.key?(:file_template_id)

    # check the datafile can be saved, and also the content blob can be saved
    all_valid = all_valid && @data_file.save && blob.save

    if all_valid

      update_relationships(@data_file, params)      
      

      respond_to do |format|
        flash[:notice] = "#{t('data_file')} was successfully uploaded and saved." if flash.now[:notice].nil?
        # parse the data file if it is with sample data

        # the assay_id param can also contain the relationship type
        @data_file.assays << @assay if @create_new_assay
        format.html { redirect_to params[:single_page] ? 
          { controller: :single_pages, action: :show, id: params[:single_page] } 
          : data_file_path(@data_file) }
        format.json { render json: @data_file, include: [params[:include]] }
      end

    else
      @data_file.errors.add(:base, "The file uploaded doesn't match") unless uploaded_blob_matches

      # this helps trigger the complete validation error messages, as not both may be validated in a single action
      # - want the avoid the user fixing one set of validation only to be presented with a new set
      @assay.valid? if @create_new_assay
      @data_file.valid? if uploaded_blob_matches
      param = params[:single_page] ? {single_page: params[:single_page]} : {}
      respond_to do |format|
        format.html do
          render :provide_metadata, params: param, status: :unprocessable_entity
        end
      end
    end
  end

  protected

  def get_sample_type
    if params[:sample_type_id] || @data_file.possible_sample_types.count == 1
      if params[:sample_type_id]
        @sample_type = SampleType.includes(:sample_attributes).find(params[:sample_type_id])
      else
        @sample_type = @data_file.possible_sample_types.last
      end
    elsif @data_file.possible_sample_types.count > 1
      # Redirect to sample type selector
      respond_to do |format|
        format.html { redirect_to select_sample_type_data_file_path(@data_file) }
      end
    else
      flash[:error] = "Couldn't determine the sample type of this data"
      respond_to do |format|
        format.html { redirect_to @data_file }
      end
    end
  end

  def check_already_extracted
    if @data_file.extracted_samples.any?
      flash[:error] = 'Already extracted samples from this data file'
      respond_to do |format|
        format.html { redirect_to @data_file }
      end
    end
  end

  def forbid_new_version_if_samples
    if @data_file.extracted_samples.any?
      flash[:error] = "Cannot upload a new version if samples have been extracted"
      respond_to do |format|
        format.html { redirect_to @data_file }
      end
    end
  end

  private

  def data_file_params
    params.require(:data_file).permit(:title, :description, :simulation_data, { project_ids: [] },
                                      :license, *creator_related_params, { event_ids: [] },
                                      { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                      { assay_assets_attributes: [:assay_id, :relationship_type_id] },
                                      { creator_ids: [] }, { assay_assets_attributes: [:assay_id, :relationship_type_id] },
                                      :file_template_id,
                                      { data_format_annotations: [] }, { data_type_annotations: [] },
                                      { publication_ids: [] }, { workflow_ids: [] },
                                      { workflow_data_files_attributes:[:id, :workflow_id, :workflow_data_file_relationship_id, :_destroy] },
                                      discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  def data_file_assay_params
    params.fetch(:assay,{}).permit(:title, :description, :assay_class_id, :study_id, :sop_id,:assay_type_uri,:technology_type_uri, :create_assay)
  end

  def oauth_client
    @oauth_client = Nels::Oauth2::Client.new(Seek::Config.nels_client_id,
                                             Seek::Config.nels_client_secret,
                                             nels_oauth_callback_url,
                                             "data_file_id:#{params[:id]}")
  end

  def nels_oauth_session
    @oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first
    redirect_to @oauth_client.authorize_url if !@oauth_session || @oauth_session.expired?
  end

  def rest_client
    @rest_client = Nels::Rest.client_class.new(@oauth_session.access_token)
  end
end
