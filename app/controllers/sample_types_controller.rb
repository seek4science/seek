class SampleTypesController < ApplicationController
  respond_to :html, :json
  include Seek::UploadHandling::DataUpload
  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :samples_enabled?
  before_action :check_no_created_samples, only: [:destroy]
  before_action :find_and_authorize_requested_item, except: %i[create batch_upload index new template_details]
  before_action :find_sample_type, only: %i[batch_upload template_details]
  before_action :check_isa_json_compliance, only: %i[edit update manage manage_update]
  before_action :find_assets, only: [:index]
  before_action :auth_to_create, only: %i[new create]
  before_action :project_membership_required, only: %i[create new select filter_for_select]


  api_actions :index, :show, :create, :update, :destroy

  # GET /sample_types/1  ,'sample_attributes','linked_sample_attributes'
  # GET /sample_types/1.json
  def show
    respond_to do |format|
      format.html
      format.json { render json: @sample_type, include: [params[:include]] }
    end
  end

  # GET /sample_types/new
  # GET /sample_types/new.json
  def new
    @tab = 'manual'

    attr = params['sample_type'] ? sample_type_params : {}
    @sample_type = SampleType.new(attr)
    @sample_type.sample_attributes.build(is_title: true, required: true) # Initial attribute

    respond_with(@sample_type)
  end

  def create_from_template
    build_sample_type_from_template
    @sample_type.contributor = User.current_user.person

    @tab = 'from-template'

    respond_to do |format|
      if @sample_type.errors.empty? && @sample_type.save
        format.html { redirect_to edit_sample_type_path(@sample_type), notice: 'Sample type was successfully created.' }
      else
        @sample_type.content_blob.destroy if @sample_type.content_blob.persisted?
        format.html { render action: 'new' }
      end
    end
  end

  # GET /sample_types/1/edit
  def edit
    respond_with(@sample_type)
  end

  # POST /sample_types
  # POST /sample_types.json
  def create
    @sample_type = SampleType.new(sample_type_params)
    @sample_type.contributor = User.current_user.person

    # Update sharing policies
    update_sharing_policies(@sample_type)
    # Update relationships
    update_relationships(@sample_type, params)
    # Update tags
    update_annotations(params[:tag_list], @sample_type)

    # removes controlled vocabularies or linked seek samples where the type may differ
    @sample_type.resolve_inconsistencies
    @tab = 'manual'

    respond_to do |format|
      if @sample_type.save
        format.html { redirect_to @sample_type, notice: 'Sample type was successfully created.' }
        format.json { render json: @sample_type, status: :created, location: @sample_type, include: [params[:include]] }
      else
        format.html { render action: 'new' }
        format.json { render json: @sample_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sample_types/1
  # PUT /sample_types/1.json
  def update

    @sample_type.update(sample_type_params)
    @sample_type.resolve_inconsistencies

    # Update sharing policies
    update_sharing_policies(@sample_type)
    # Update relationships
    update_relationships(@sample_type, params)
    # Update tags
    update_annotations(params[:tag_list], @sample_type)

    respond_to do |format|
      if @sample_type.save
        format.html { redirect_to @sample_type, notice: 'Sample type was successfully updated.' }
        format.json { render json: @sample_type, include: [params[:include]] }
      else
        format.html { render action: 'edit', status: :unprocessable_entity }
        format.json { render json: @sample_type.errors, status: :unprocessable_entity }
      end
    end
  end

  def template_details
    render partial: 'template'
  end

  # current just for selecting a sample type for creating a sample, but easily has potential as a general browser
  def select
    respond_with(@sample_types)
  end

  # used for ajax call to get the filtered sample types for selection
  def filter_for_select
    scope = Seek::Config.isa_json_compliance_enabled ? SampleType.without_template : SampleType
    @sample_types = scope.joins(:projects).where('projects.id' => params[:projects]).distinct.to_a
    unless params[:tags].blank?
      @sample_types.select! do |sample_type|
        if params[:exclusive_tags] == '1'
          (params[:tags] - sample_type.annotations_as_text_array).empty?
        else
          (sample_type.annotations_as_text_array & params[:tags]).any?
        end
      end
    end
    render partial: 'sample_types/select/filtered_sample_types'
  end

  def batch_upload; end

  private

  def sample_type_params
    attributes = params[:sample_type][:sample_attributes]
    if attributes
      params[:sample_type][:sample_attributes_attributes] = []
      attributes.each do |attribute|
        if attribute[:sample_attribute_type]
          if attribute[:sample_attribute_type][:id]
            attribute[:sample_attribute_type_id] = attribute[:sample_attribute_type][:id].to_i
          elsif attribute[:sample_attribute_type][:title]
            attribute[:sample_attribute_type_id] =
              SampleAttributeType.where(title: attribute[:sample_attribute_type][:title]).first.id
          end
        end
        attribute[:unit_id] = Unit.where(symbol: attribute[:unit_symbol]).first.id unless attribute[:unit_symbol].nil?
        params[:sample_type][:sample_attributes_attributes] << attribute
      end
    end

    if params[:sample_type][:assay_assets_attributes]
      params[:sample_type][:assay_ids] = params[:sample_type][:assay_assets_attributes].map { |x| x[:assay_id] }
    end

    params.require(:sample_type).permit(:title, :description, { tags: [] }, :template_id, *creator_related_params,
                                        { project_ids: [],
                                          sample_attributes_attributes: %i[id title pos required is_title
                                                                           description pid sample_attribute_type_id
                                                                           sample_controlled_vocab_id isa_tag_id
                                                                           allow_cv_free_text linked_sample_type_id
                                                                           unit_id _destroy] }, assay_ids: [])
  end


  def build_sample_type_from_template
    @sample_type = SampleType.new(sample_type_params)
    @sample_type.uploaded_template = true

    handle_upload_data
    @sample_type.content_blob.save! # Need's to be saved so the spreadsheet can be read from disk
    @sample_type.build_attributes_from_template
  end

  def check_isa_json_compliance
    @sample_type ||= SampleType.find(params[:id])
    return unless Seek::Config.isa_json_compliance_enabled && @sample_type.is_isa_json_compliant?

    flash[:error] = 'This sample type is ISA JSON compliant and cannot be managed.'
    redirect_to sample_types_path
  end

  def find_sample_type
    scope = Seek::Config.isa_json_compliance_enabled ? SampleType.without_template : SampleType
    @sample_type = scope.find(params[:id])
  end

  def check_no_created_samples
    @sample_type ||= SampleType.find(params[:id])
    if (count = @sample_type.samples.count).positive?
      flash[:error] = "Cannot #{action_name} this sample type - There are #{count} samples using it."
      redirect_to @sample_type
    end
  end
end
