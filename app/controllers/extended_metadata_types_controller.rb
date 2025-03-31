class ExtendedMetadataTypesController < ApplicationController
  respond_to :json, :html
  skip_before_action :project_membership_required

  before_action :fair_data_station_enabled?, only:[:create_from_fair_ds_ttl]
  before_action :is_user_admin_auth, except: [:form_fields, :show, :index]
  before_action :find_requested_item, only: [:administer_update, :show, :destroy]
  include Seek::IndexPager
  after_action :log_event, only: [:create, :destroy]

  api_actions :index, :show

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

  def create

    if params[:emt_json_file].blank?
      flash[:error] = 'Please select a file to upload!'
      redirect_to new_extended_metadata_type_path and return
    end

    uploaded_file = params[:emt_json_file]
    @extended_metadata_type = Seek::ExtendedMetadataType::ExtendedMetadataTypeExtractor.extract_extended_metadata_type(uploaded_file)

    if @extended_metadata_type.save
      flash[:notice] = 'Extended metadata type was successfully created.'
       redirect_to administer_extended_metadata_types_path(emt: @extended_metadata_type.id)
    else
      flash[:error] = @extended_metadata_type.errors.full_messages.join(', ')
      redirect_to new_extended_metadata_type_path
    end
  rescue StandardError => e
    flash[:error] = e.message
    redirect_to new_extended_metadata_type_path
  end

  def create_from_fair_ds_ttl
    if params[:emt_fair_ds_ttl_file].blank?
      flash[:error] = 'Please select a file to upload!'
      redirect_to new_extended_metadata_type_path and return
    end

    uploaded_file = params[:emt_fair_ds_ttl_file]
    @jsons = []
    @existing_extended_metadata_types = []
    Tempfile.create('fds-ttl') do |file|
      file << uploaded_file.read.force_encoding('UTF-8')
      Seek::FairDataStation::Reader.new.candidates_for_extended_metadata(file.path).each do |candidate|
        emt = candidate.find_exact_matching_extended_metadata_type
        if emt
          @existing_extended_metadata_types << emt
        else
          @jsons << candidate.to_extended_metadata_type_json
        end
      end
    end

    respond_to do |format|
      format.html
    end
  end

  def submit_jsons
    jsons = params['emt_jsons']
    titles = params['emt_titles']
    failures = []
    successes = []
    jsons.zip(titles).each do |json, title|
      begin
        extended_metadata_type = Seek::ExtendedMetadataType::ExtendedMetadataTypeExtractor.extract_extended_metadata_type(StringIO.new(json))
        extended_metadata_type.title = title
        extended_metadata_type.activity_logs.build(culprit: current_user, action: 'create')
        if extended_metadata_type.save
          successes << "#{extended_metadata_type.title}(#{extended_metadata_type.supported_type})"
        else
          failures << "#{extended_metadata_type.title}(#{extended_metadata_type.supported_type}) - #{extended_metadata_type.errors.full_messages.join(', ')}"
        end
      rescue JSON::ParserError
        failures << "Failed to parse JSON"
      rescue StandardError => e
        failures << e.message
      end
    end
    if successes.any?
      flash[:notice] = "#{successes.count} #{t('extended_metadata_type').pluralize(successes.count)} successfully created for: #{successes.join(', ')}."
    end
    if failures.any?
      flash[:error] = "#{failures.count} #{t('extended_metadata_type').pluralize(failures.count)} failed to be created: #{failures.join(', ')}."
    end

    redirect_to administer_extended_metadata_types_path
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
     end
  end

  def destroy

    # if a nested metadata type is linked by other metadata types
    return if @extended_metadata_type.linked_metadata_attributes.any?

    # if a top level metadata type has been used to create metadatas
    return if @extended_metadata_type.extended_metadatas.present?

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
    if params[:emt]
      @extended_metadata_type = ExtendedMetadataType.find(params[:emt])
    end
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

    return if object_invalid_or_unsaved?(@extended_metadata_type)

    ActivityLog.create(action: action_name.downcase,
                       culprit: current_user,
                       controller_name: self.controller_name.downcase,
                       activity_loggable: object_for_request,
                        data: object_for_request.title,
                        user_agent: request.env['HTTP_USER_AGENT'])

  end

end
