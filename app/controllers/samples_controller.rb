class SamplesController < ApplicationController
  respond_to :html
  include Seek::PreviewHandling
  include Seek::AssetsCommon
  include Seek::IndexPager
  include Seek::JSONMetadata

  before_action :samples_enabled?
  before_action :find_index_assets, only: :index
  before_action :find_and_authorize_requested_item, except: [:index, :new, :create, :preview]
  
  before_action :auth_to_create, only: [:new, :create]

  
  include Seek::IsaGraphExtensions

  def index
    # There must be better ways of coding this
    if @data_file || @sample_type
      respond_to do |format|
        format.html { render(params[:only_content] ? { layout: false } : {})}
        format.json {render json: :not_implemented, status: :not_implemented }
      end
    else
      respond_to do |format|
        format.html {params[:only_content] ? render({ layout: false }) : super}
        format.json {render json: :not_implemented, status: :not_implemented }
      end
    end
  end

  def new
    if params[:sample_type_id]
      @sample = Sample.new(sample_type_id: params[:sample_type_id])
      respond_with(@sample)
    else
      redirect_to select_sample_types_path
    end
  end

  def create
    @sample = Sample.new(sample_type_id: params[:sample][:sample_type_id], title: params[:sample][:title])
    if update_sample_with_params
      respond_to do |format|
        flash[:notice] = 'The sample was successfully created.'
        format.html { redirect_to sample_path(@sample) }
        format.json { render json: @sample }
      end
    else
      respond_to do |format|
        format.html { render :action => "new" }
        format.json { render json: json_api_errors(@sample), status: :unprocessable_entity }
      end
    end

  end

  def show
    @sample = Sample.find(params[:id])
    respond_to do |format|
      format.html
      format.json {render json: @sample, include: [params[:include]]}
    end
  end

  def edit
    @sample = Sample.find(params[:id])
    respond_with(@sample)
  end

  def update
    @sample = Sample.find(params[:id])
    respond_to do |format|
      if update_sample_with_params
        flash[:notice] = 'The sample was successfully updated.'
        format.html { redirect_to sample_path(@sample) }
        format.json { render json: @sample }
      else
        flash[:error] = 'It was not possible to update the sample.'
        format.html { redirect_to root_path }
        format.json {render json: {:status => 403}, :status => 403}
      end
    end
  end

  def destroy
    @sample = Sample.find(params[:id])
    respond_to do |format|
      if @sample.can_delete? && @sample.destroy
        flash[:notice] = 'The sample was successfully deleted.'
        format.html { redirect_to root_path }
        format.json {render json: {status: :ok}, status: :ok}
      else
        flash[:error] = 'It was not possible to delete the sample.'
        format.html { redirect_to root_path }
        format.json {render json: {:status => 403}, :status => 403}
      end
    end
  end

  # called from AJAX, returns the form containing the attributes for the sample_type_id
  def attribute_form
    sample_type_id = params[:sample_type_id]

    sample = Sample.new(sample_type_id: sample_type_id)

    respond_with do |format|
      format.js do
        render json: {
          form: (render_to_string(partial: 'samples/sample_attributes_form', locals: { sample: sample }))
        }
      end
    end
  end

  def filter
    @associated_samples = params[:assay_id].blank? ? [] : Assay.find(params[:assay_id]).samples
    @samples = Sample.where('title LIKE ?', "%#{params[:filter]}%").limit(20)

    respond_with do |format|
      format.html do
        render partial: 'samples/association_preview', collection: @samples,
               locals: { existing: @associated_samples }
      end
    end
  end

  def batch_create
    errors, results = [], []
    param_converter = Seek::Api::ParameterConverter.new("samples")
    Sample.transaction do
      params[:data].each do |par|
        converted_params = param_converter.convert(par)
        sample_type = SampleType.find_by_id(converted_params.dig(:sample, :sample_type_id))
        sample = Sample.new(sample_type: sample_type)
        if update_sample_with_params(converted_params, sample)
          results.push({ ex_id: par[:ex_id], id: sample.id })
        else
          errors.push({ ex_id: par[:ex_id], error: sample.errors.messages })
        end
      end
      raise ActiveRecord::Rollback if errors.any?
    end
    status = errors.empty? ? :ok : :unprocessable_entity
    render json: { status: status, errors: errors, results: results }, status: :ok
  end

  def batch_update
    errors = []
    param_converter = Seek::Api::ParameterConverter.new("samples")
    Sample.transaction do
      params[:data].each do |par|
        begin
          converted_params = param_converter.convert(par)
          sample = Sample.find(par[:id])
          saved = update_sample_with_params(converted_params, sample)
          errors.push({ ex_id: par[:ex_id], error: sample.errors.messages }) unless saved
        rescue
          errors.push({ ex_id: par[:ex_id], error: "Can not be updated." })
        end
      end
      raise ActiveRecord::Rollback if errors.any?
    end
    status = errors.empty? ? :ok : :unprocessable_entity
    render json: { status: status, errors: errors }, status: :ok
  end

  def batch_delete
    errors = []
    Sample.transaction do
      params[:data].each do |par|
        begin
          sample = Sample.find(par[:id])
          errors.push({ ex_id: par[:ex_id], error: "Can not be deleted." }) if !(sample.can_delete? && sample.destroy)
        rescue 
          errors.push({ ex_id: par[:ex_id], error: sample.errors.messages })
        end         
      end
      raise ActiveRecord::Rollback if errors.any?
    end
    status = errors.empty? ? :ok : :unprocessable_entity
    render json: { status: status, errors: errors }, status: :ok
  end


  def typeahead
    sample_type = SampleType.find(params[:linked_sample_type_id])
    results = sample_type.samples.where("LOWER(title) like :query",
              query: "%#{params[:query].downcase}%").limit(params[:limit] || 100)
    items = results.map do |sa|
      { id: sa.id,
        name: sa.title }
    end

    respond_to do |format|
      format.json { render json: items.to_json }
    end
  end

  private

  def sample_params(sample_type = nil, parameters = params)
    sample_type_param_keys = sample_type ? sample_type.sample_attributes.map(&:title).collect(&:to_sym) : []
    if parameters[:sample][:attribute_map]
      parameters[:sample][:data] = parameters[:sample].delete(:attribute_map)
    end
    if (parameters[:sample][:assay_assets_attributes])
      parameters[:sample][:assay_ids] = parameters[:sample][:assay_assets_attributes].map { |x| x[:assay_id] }
    end
    parameters.require(:sample).permit(:sample_type_id, *creator_related_params,
                              { project_ids: [] }, { data: sample_type_param_keys },
                              { assay_ids: [] },
                              { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                              discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  def update_sample_with_params(parameters = params, sample = @sample)
    sample.assign_attributes(sample_params(sample.sample_type, parameters))
    update_sharing_policies(sample, parameters)
    update_annotations(parameters[:tag_list], sample)
    update_relationships(sample, parameters)
    sample.save
  end

  def find_index_assets
    if params[:data_file_id]
      @data_file = DataFile.find(params[:data_file_id])

      unless @data_file.can_view?
        flash[:error] = 'You are not authorize to view samples from this data file'
        respond_to do |format|
          format.html { redirect_to data_file_path(@data_file) }
        end
      end

      @samples = @data_file.extracted_samples.includes(sample_type: :sample_attributes).authorized_for('view')
    elsif params[:sample_type_id]
      @sample_type = SampleType.includes(:sample_attributes).find(params[:sample_type_id])
      @samples = @sample_type.samples.authorized_for('view')
    else
      find_assets
    end
  end
end
