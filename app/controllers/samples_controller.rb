class SamplesController < ApplicationController
  respond_to :html
  include Seek::PreviewHandling
  include Seek::AssetsCommon
  include Seek::IndexPager
  include Seek::JSONMetadata

  before_action :samples_enabled?
  before_action :find_index_assets, only: :index
  before_action :find_and_authorize_requested_item, except: [:index, :new, :create, :preview]
  before_action :templates_enabled?, only: [:query, :query_form]

  before_action :auth_to_create, only: %i[new create batch_create]

  include Seek::IsaGraphExtensions
  include Seek::Publishing::PublishingCommon

  def index
    # There must be better ways of coding this
    if @data_file || @sample_type
      respond_to do |format|
        format.html { render(params[:only_content] ? { layout: false } : {})}
        format.json do
          render json: instance_variable_get("@#{controller_name}"),
                 each_serializer: SkeletonSerializer,
                 links: json_api_links,
                 meta: {
                     base_url: Seek::Config.site_base_host,
                     api_version: ActiveModel::Serializer.config.api_version
                 }
        end
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
      @sample = Sample.new(sample_type_id: params[:sample_type_id], project_ids: params[:project_ids])
      respond_with(@sample)
    else
      project_ids_param = params[:sample] ? params[:sample][:project_ids] : {}
      redirect_to select_sample_types_path(act: :create, project_ids: project_ids_param)
    end
  end

  def create
    @sample = Sample.new(sample_type_id: params[:sample][:sample_type_id], title: params[:sample][:title])
    @sample = update_sample_with_params
    if @sample.save
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
    if !@sample.originating_data_file.nil? && @sample.edit_count.zero?
      flash.now[:error] = '<strong>Warning:</strong> This sample was extracted from a datafile.
                           If you edit the sample, it will no longer correspond to the original source data.<br/>
                           Unless you cancel, a label will be added to the sample\'s source field to indicate it is no longer valid.'.html_safe
    end
    respond_with(@sample)
  end

  def update
    @sample = Sample.find(params[:id])
    @sample = update_sample_with_params
    respond_to do |format|
      if @sample.save
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
    errors = []
    results = []
    param_converter = Seek::Api::ParameterConverter.new("samples")
    Sample.transaction do
      params[:data].each do |par|
        converted_params = param_converter.convert(par)
        sample_type = SampleType.find_by_id(converted_params.dig(:sample, :sample_type_id))
        sample = Sample.new(sample_type: sample_type)
        sample = update_sample_with_params(converted_params, sample)
        if sample.save
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
          raise 'shouldnt get this far without manage rights' unless sample.can_manage?
          sample = update_sample_with_params(converted_params, sample)
          saved = sample.save
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
    query = params[:q] || ''
    sample_type = SampleType.find(params[:linked_sample_type_id])
    results = sample_type.samples.where("LOWER(title) like :query",
              query: "%#{query.downcase}%").limit(params[:limit] || 100).authorized_for(:view)
    items = results.map do |sa|
      { id: sa.id,
        text: sa.title }
    end

    respond_to do |format|
      format.json { render json: { results: items}.to_json }
    end
  end

  def query
    project_ids = params[:project_ids]&.map(&:to_i)

    @result = params[:template_id].present? ?
      Template.find(params[:template_id]).sample_types.map(&:samples).flatten : []

    if params[:template_attribute_id].present? && params[:template_attribute_value].present?
      attribute_title = TemplateAttribute.find(params[:template_attribute_id]).title
      @result = @result.select { |s| s.get_attribute_value(attribute_title)&.include?(params[:template_attribute_value]) }
    end

    if params[:input_template_id].present? # linked
      title =
        TemplateAttribute.find(params[:input_attribute_id]).title if params[:input_attribute_id].present?
      @result = find_samples(@result, :linked_samples,
        { attribute_id: params[:input_attribute_id],
          attribute_value: params[:input_attribute_value],
          template_id: params[:input_template_id] }, title)
    end

    if params[:output_template_id].present? # linking
      title =
        TemplateAttribute.find(params[:output_attribute_id]).title if params[:output_attribute_id].present?
      @result = find_samples(@result, :linking_samples,
        { attribute_id: params[:output_attribute_id],
          attribute_value: params[:output_attribute_value],
          template_id: params[:output_template_id] }, title)
    end

    @result = @result.select { |s| (project_ids & s.project_ids).any? } if project_ids.present?
    @total_samples = @result.length
    @result = @result.any? ? @result.authorized_for('view') : []
    @visible_samples = @result.length

    respond_to do |format|
      format.js
    end
  end

  def query_form
    @result = []
    respond_to do |format|
      format.html
    end
  end

  private

  def sample_params(sample_type = nil, parameters = params)

    sample_type_param_keys = []

    if sample_type
      sample_type.sample_attributes.each do |attr|
        if attr.sample_attribute_type.controlled_vocab? || attr.sample_attribute_type.seek_sample_multi? || attr.sample_attribute_type.seek_sample?
          sample_type_param_keys << { attr.title => [] }
          sample_type_param_keys << attr.title.to_sym
        else
          sample_type_param_keys << attr.title.to_sym
        end
      end
    end
    parameters.require(:sample).permit(:sample_type_id, *creator_related_params,
                              { project_ids: [] }, { data: sample_type_param_keys },
                              { assay_assets_attributes: [:assay_id] },
                              { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                              discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

  def update_sample_with_params(parameters = params, sample = @sample)
    sample.assign_attributes(sample_params(sample.sample_type, parameters))
    update_sharing_policies(sample, parameters)
    update_annotations(parameters[:tag_list], sample)
    update_relationships(sample, parameters)
    sample
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
    elsif params[:template_id]
      @template = Template.find(params[:template_id])
      @samples = @template.samples.authorized_for('view')
    else
      find_assets
    end
  end

  def find_samples(samples, link, options, title)
    samples.select do |s|
      s.send(link).any? do |x|
        selected = x.sample_type.template_id == options[:template_id].to_i
        selected = x.get_attribute_value(title)&.include?(options[:attribute_value]) if title.present? && selected
        selected || find_samples([x], link, options, title).present?
      end
    end
  end

  def templates_enabled?
    unless Seek::Config.isa_json_compliance_enabled
      flash[:error] = 'Not available'
      redirect_to select_sample_types_path
    end
  end
end
