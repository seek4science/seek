class SampleTypesController < ApplicationController
  respond_to :html, :json
  include Seek::UploadHandling::DataUpload
  include Seek::IndexPager

  before_action :samples_enabled?
  before_action :find_sample_type, only: [:show, :edit, :update, :destroy, :template_details, :batch_upload]
  before_action :check_no_created_samples, only: [:destroy]
  before_action :find_assets, only: [:index]
  before_action :auth_to_create, only: [:new, :create]
  before_action :project_membership_required, only: [:create, :new, :select, :filter_for_select]

  before_action :authorize_requested_sample_type, except: [:index, :new, :create]

  api_actions :index

  # GET /sample_types/1  ,'sample_attributes','linked_sample_attributes'
  # GET /sample_types/1.json
  def show
    respond_to do |format|
      format.html
      format.json {render json: @sample_type, include: [params[:include]]}
    end
  end

  # GET /sample_types/new
  # GET /sample_types/new.json
  def new
    @tab = 'manual'

    @sample_type = SampleType.new
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

    # removes controlled vocabularies or linked seek samples where the type may differ
    @sample_type.resolve_inconsistencies
    @tab = 'manual'

    respond_to do |format|
      if @sample_type.save
        format.html { redirect_to @sample_type, notice: 'Sample type was successfully created.' }
        format.json { render json: @sample_type, status: :created, location: @sample_type, include: [params[:include]]}
      else
        format.html { render action: 'new' }
        format.json { render json: @sample_type.errors, status: :unprocessable_entity}
      end
    end
  end

  # PUT /sample_types/1
  # PUT /sample_types/1.json
  def update

    @sample_type.update_attributes(sample_type_params)
    @sample_type.resolve_inconsistencies
    respond_to do |format|
      if @sample_type.save
        format.html { redirect_to @sample_type, notice: 'Sample type was successfully updated.' }
        format.json {render json: @sample_type, include: [params[:include]]}
      else
        format.html { render action: 'edit', status: :unprocessable_entity }
        format.json { render json: @sample_type.errors, status: :unprocessable_entity}
      end
    end
  end

  # DELETE /sample_types/1
  # DELETE /sample_types/1.json
  def destroy
    respond_to do |format|
    if @sample_type.can_delete? && @sample_type.destroy
      format.html { redirect_to @sample_type,location: sample_types_path, notice: 'Sample type was successfully deleted.' }
      format.json {render json: @sample_type, include: [params[:include]]}
    else
      format.html { redirect_to @sample_type, location: sample_types_path, notice: 'It was not possible to delete the sample type.' }
      format.json { render json: @sample_type.errors, status: :unprocessable_entity}
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
    @sample_types = SampleType.joins(:projects).where('projects.id' => params[:projects]).distinct.to_a
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

  def batch_upload

  end

  private

  def sample_type_params
    attributes = params[:sample_type][:sample_attributes]
    if (attributes)
      params[:sample_type][:sample_attributes_attributes] = []
      attributes.each do |attribute|
        if attribute[:sample_attribute_type]
          if attribute[:sample_attribute_type][:id]
            attribute[:sample_attribute_type_id] = attribute[:sample_attribute_type][:id].to_i
          elsif attribute[:sample_attribute_type][:title]
            attribute[:sample_attribute_type_id] = SampleAttributeType.where(title: attribute[:sample_attribute_type][:title]).first.id
          end
        end
        attribute[:unit_id] = Unit.where(symbol: attribute[:unit_symbol]).first.id unless attribute[:unit_symbol].nil?
        params[:sample_type][:sample_attributes_attributes] << attribute
      end
    end

    if (params[:sample_type][:assay_assets_attributes])
      params[:sample_type][:assay_ids] = params[:sample_type][:assay_assets_attributes].map { |x| x[:assay_id] }
    end

    params.require(:sample_type).permit(:title, :description, :tags, :template_id,
                                        { project_ids: [],
                                          sample_attributes_attributes: [:id, :title, :pos, :required, :is_title,
                                                                         :description, :pid, :sample_attribute_type_id,
                                                                         :sample_controlled_vocab_id, :isa_tag_id,
                                                                         :linked_sample_type_id,
                                                                         :unit_id, :_destroy] }, :assay_ids => [])
  end


  def build_sample_type_from_template
    @sample_type = SampleType.new(sample_type_params)
    @sample_type.uploaded_template = true

    handle_upload_data
    @sample_type.content_blob.save! # Need's to be saved so the spreadsheet can be read from disk
    @sample_type.build_attributes_from_template
  end

  private

  def find_sample_type
    @sample_type = SampleType.find(params[:id])
  end

  #intercepts the standard 'find_and_authorize_requested_item' for additional special check for a referring_sample_id
  def authorize_requested_sample_type
    privilege = Seek::Permissions::Translator.translate(action_name)
    return if privilege.nil?

    if privilege == :view && params[:referring_sample_id].present?
      @sample_type.can_view?(User.current_user,Sample.find_by_id(params[:referring_sample_id])) || find_and_authorize_requested_item
    else
      find_and_authorize_requested_item
    end

  end

  def check_no_created_samples
    if (count = @sample_type.samples.count) > 0
      flash[:error] = "Cannot #{action_name} this sample type - There are #{count} samples using it."
      redirect_to @sample_type
    end
  end
end
