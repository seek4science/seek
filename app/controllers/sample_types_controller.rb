class SampleTypesController < ApplicationController
  respond_to :html
  include Seek::UploadHandling::DataUpload
  include Seek::IndexPager

  before_filter :samples_enabled?
  before_filter :find_sample_type, only: [:show, :edit, :update, :destroy, :template_details]
  before_filter :check_no_created_samples, only: [:destroy]
  before_filter :find_assets, only: [:index]
  before_filter :auth_to_create, only: [:new, :create]
  before_filter :project_membership_required, only: [:create, :new, :select, :filter_for_select]

  # these checks are mostly coverered by the #check_no_created_samples filter, but will give an additional check based on can_xxx? methods
  before_filter :find_and_authorize_requested_item, except: [:index, :new, :create]

  # GET /sample_types/1
  # GET /sample_types/1.json
  def show
    respond_with(@sample_type)
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

    @tab = 'from-template'

    respond_to do |format|
      if @sample_type.errors.empty? && @sample_type.save
        format.html { redirect_to edit_sample_type_path(@sample_type), notice: 'Sample type was successfully created.' }
      else
        @sample_type.content_blob.destroy if @sample_type.content_blob
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
    # because setting tags does an unfortunate save, these need to be updated separately to avoid a permissions to edit error
    tags = params[:sample_type].delete(:tags)
    @sample_type = SampleType.new(params[:sample_type])

    # removes controlled vocabularies or linked seek samples where the type may differ
    @sample_type.resolve_inconsistencies
    @tab = 'manual'

    respond_to do |format|
      if @sample_type.save
        @sample_type.update_attribute(:tags, tags)
        format.html { redirect_to @sample_type, notice: 'Sample type was successfully created.' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # PUT /sample_types/1
  # PUT /sample_types/1.json
  def update
    @sample_type.update_attributes(params[:sample_type])
    @sample_type.resolve_inconsistencies
    flash[:notice] = 'Sample type was successfully updated.' if @sample_type.save
    respond_with(@sample_type)
  end

  # DELETE /sample_types/1
  # DELETE /sample_types/1.json
  def destroy
    if @sample_type.can_delete? && @sample_type.destroy
      flash[:notice] = 'The sample type was successfully deleted.'
    else
      flash[:notice] = 'It was not possible to delete the sample type.'
    end

    respond_with(@sample_type, location: sample_types_path)
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
    @sample_types = SampleType.joins(:projects).where('projects.id' => params[:projects])
    unless params[:tags].blank?
      @sample_types.select! do |sample_type|
        if params[:exclusive_tags] == '1'
          (params[:tags] - sample_type.annotations_as_text_array).empty?
        else
          (sample_type.annotations_as_text_array & params[:tags]).any?
        end
      end
    end
    @sample_types.uniq!
    render partial: 'sample_types/select/filtered_sample_types'
  end

  private

  def build_sample_type_from_template
    @sample_type = SampleType.new(params[:sample_type])
    @sample_type.uploaded_template = true

    handle_upload_data
    attributes = build_attributes_hash_for_content_blob(content_blob_params.first, nil)
    @sample_type.create_content_blob(attributes)
    @sample_type.build_attributes_from_template
  end

  def find_sample_type
    @sample_type = SampleType.find(params[:id])
  end

  def check_no_created_samples
    if (count = @sample_type.samples.count) > 0
      flash[:error] = "Cannot #{action_name} this sample type - There are #{count} samples using it."
      redirect_to @sample_type
    end
  end
end
