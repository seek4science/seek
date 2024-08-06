class ExtendedMetadataTypesController < ApplicationController
  respond_to :json, :html
  skip_before_action :project_membership_required
  before_action :is_user_admin_auth, except: [:form_fields, :show, :index]
  before_action :find_requested_item, only: [:administer_update, :show, :destroy]
  include Seek::IndexPager
  include Seek::UploadHandling::DataUpload
  after_action :log_event, only: [:emt_populate_job_status], if: -> { @status == 'completed' }

  # generated for form, to display fields for selected metadata type
  def form_fields
    id = params[:id]
    parent_resource = params[:parentResource] unless params[:parentResource]&.empty?
    respond_to do |format|
      if id.blank?
        format.html { render html: '' }
      else
        cm = ExtendedMetadataType.find(id)
        resource = safe_class_lookup(cm.supported_type).new
        resource.extended_metadata = ExtendedMetadata.new(extended_metadata_type: cm)
        format.html do
          render partial: 'extended_metadata/extended_metadata_fields',
                 locals: { extended_metadata_type: cm, resource: resource, parent_resource: parent_resource}
        end
      end
    end
  end


  def upload_file
    dir = Seek::Config.append_filestore_path('emt_files')
    uploaded_file = params[:emt_json_file]
    filepath = Rails.root.join(dir, uploaded_file.original_filename)
    File.write(filepath, uploaded_file.read)

    job = PopulateExtendedMetadataTypeJob.new(filepath.to_s).queue_job

    session[:job_id] = job.provider_job_id
    # Redirect or respond to indicate the job has been started
    respond_to do |format|
      format.html {
 redirect_to administer_extended_metadata_types_path, 
             notice: 'Your JSON file for extracting the extended metadata type has been uploaded. ' }
    end
  end

  def populate_job_status
    job = Delayed::Job.find_by(id: session[:job_id])
    @status = if job.nil?
               session.delete(:job_id)
               'completed'
             else
               'processing'
             end

    respond_to do |format|
      format.json { render json: { status: @status } }
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
       format.json {render json: @extended_metadata_type}
       format.html
     end
  end

  def index
    @extended_metadata_types = ExtendedMetadataType.all.reject { |type| type.supported_type == 'ExtendedMetadata' }
    respond_to do |format|
       format.json do
         render json:  @extended_metadata_types,
                each_serializer: SkeletonSerializer,
                links: json_api_links,
                meta: {
                  base_url: Seek::Config.site_base_host,
                  api_version: ActiveModel::Serializer.config.api_version
                }
       end
       format.html
     end
  end

  def destroy
    if @extended_metadata_type.destroy
      flash[:notice] = 'Extended metadata type was successfully deleted.'
    else
      flash[:alert] = 'Failed to delete the extended metadata type.'
    end
    respond_to do |format|
      format.html { redirect_to administer_extended_metadata_types_path }
    end
  end

  def administer_update
    @extended_metadata_type.update(extended_metadata_type_params)
    unless @extended_metadata_type.save
      flash[:error] = "Unable to save"
    end
    respond_to do |format|
      format.html { redirect_to administer_extended_metadata_types_path }
    end
  end

  def administer
    @extended_metadata_types = ExtendedMetadataType.order(:supported_type)
    respond_to do |format|
      format.html
    end
  end

  private

  def extended_metadata_type_params
    params.require(:extended_metadata_type).permit(:title, :enabled)
  end

  def log_event
    User.with_current_user current_user do
      ActivityLog.create(action: 'create',
                         culprit: current_user,
                         controller_name:self.controller_name.downcase,
                         # todo: if this is the correct way to get the newest created extended_metadata_type
                         activity_loggable: ExtendedMetadataType.all.last
                       )

    end
  end


end
