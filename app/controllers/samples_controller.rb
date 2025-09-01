class SamplesController < ApplicationController
  respond_to :html
  include Seek::PreviewHandling
  include Seek::AssetsCommon
  include Seek::IndexPager
  include Seek::JSONMetadata

  before_action :samples_enabled?
  before_action :find_index_assets, only: :index
  before_action :find_and_authorize_requested_item, except: [:index, :new, :create, :preview]
  before_action :check_if_locked_sample_type, only: %i[edit new create update]
  before_action :authorize_sample_type, only: %i[new create]
  before_action :templates_enabled?, only: [:query, :query_form]

  before_action :auth_to_create, only: %i[new create batch_create]

  include Seek::ISAGraphExtensions
  include Seek::Publishing::PublishingCommon

  api_actions :index, :show, :create, :update, :destroy, :batch_create

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
      format.rdf { render template: 'rdf/show' }
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
    sample_type_id = params.permit(:sample_type_id).dig(:sample_type_id)
    parameters = batch_upload_sample_params(params, sample_type_id)
    sample_type = SampleType.find(sample_type_id)

    if sample_type.nil?
      err_message = "Sample Type with ID '#{sample_type_id}' not found."
      errors.push err_message
      raise err_message
    end

    if sample_type.locked?
      err_message = 'Batch upload not allowed. Sample Type is currently locked! Wait until the lock is removed and try again.'
      errors.push err_message
      raise err_message
    end

    if parameters.count < 100
      batch_create_processor = Samples::SampleBatchProcessor.new(sample_type_id: sample_type_id,
                                                                 batch_process_params: parameters,
                                                                 user: @current_user)
      batch_create_processor.create!
      results.concat(batch_create_processor.results)
      errors.concat(batch_create_processor.errors)
      raise "The following errors occurred: #{errors.join("\n")}" unless errors.empty?
    else
      SamplesBatchCreateJob.perform_later(sample_type_id, parameters, @current_user, true)
      results = ['A background job has been launched.']
    end
    status = :ok
  rescue StandardError => e
    flash[:error] = e.message
    status = :unprocessable_entity
  ensure
    render json: {
      errors: errors,
      results: results,
      status: status
    },
    status: status
  end

  def batch_update
    errors = []
    results = []
    sample_type_id = params.permit(:sample_type_id).dig(:sample_type_id)
    parameters = batch_upload_sample_params(params, sample_type_id)
    sample_type = SampleType.find(sample_type_id)

    if sample_type.nil?
      err_message = "Sample Type with ID '#{sample_type_id}' not found."
      errors.push err_message
      raise err_message
    end

    if sample_type.locked?
      err_message = 'Batch upload not allowed. Sample Type is currently locked! Wait until the lock is removed and try again.'
      errors.push err_message
      raise err_message
    end

    if sample_type.batch_upload_in_progress?
      err_message = 'Batch upload not allowed. There is already a background job in progress for this Sample Type. Please wait and try again later.'
      errors.push err_message
      raise err_message
    end

    if parameters.count < 100
      batch_update_processor = Samples::SampleBatchProcessor.new(sample_type_id: sample_type_id,
                                                                 batch_process_params: parameters,
                                                                 user: @current_user)
      batch_update_processor.update!
      errors.concat(batch_update_processor.errors)
      results.concat(batch_update_processor.results)
      raise "The following errors occurred: #{errors.join("\n")}" unless errors.empty?
    else
      SamplesBatchUpdateJob.perform_later(sample_type_id, parameters, @current_user, true)
      results = ['A background job has been launched. This Sample Type will now lock itself as long as the background job is in progress.']
    end
    status = :ok
  rescue StandardError => e
    flash[:error] = e.message
    status = :unprocessable_entity
  ensure
    render json: {
      errors: errors,
      results: results,
      status: status
    },
    status: status
  end

  def batch_delete
    errors = []
    results = []
    sample_type_id = params.permit(:sample_type_id).dig(:sample_type_id)
    parameters = batch_delete_sample_params
    sample_type = SampleType.find(sample_type_id)

    if sample_type.nil?
      err_message = "Sample Type with ID '#{sample_type_id}' not found."
      errors.push err_message
      raise err_message
    end

    if sample_type.locked?
      err_message = 'Batch upload not allowed. Sample Type is currently locked! Wait until the lock is removed and try again.'
      errors.push err_message
      raise err_message
    end

    if sample_type.batch_upload_in_progress?
      err_message = 'Batch upload not allowed. There is already a background job in progress for this Sample Type. Please wait and try again later.'
      errors.push err_message
      raise err_message
    end

    batch_update_processor = Samples::SampleBatchProcessor.new(sample_type_id: sample_type_id,
                                                               batch_process_params: parameters,
                                                               user: @current_user)
    batch_update_processor.delete!
    errors.concat(batch_update_processor.errors)
    results.concat(batch_update_processor.results)
    raise "The following errors occurred: #{errors.join("\n")}" unless errors.empty?

    status = :ok
  rescue StandardError => e
    flash[:error] = e.message
    status = :unprocessable_entity
  ensure
    render json: {
      errors: errors,
      results: results,
      status: status
    },
           status: status
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
    attribute_filter_value = params[:template_attribute_value]&.downcase
    @result = params[:template_id].present? ?
      Template.find(params[:template_id]).sample_types.map(&:samples).flatten : []

    if params[:template_attribute_id].present? && attribute_filter_value.present?
      template_attribute = TemplateAttribute.find(params[:template_attribute_id])
      @result = @result.select do |s|
        sample_attribute = s.sample_type.sample_attributes.detect { |sa| template_attribute.sample_attributes.include? sa }
        sample_attribute_title = sample_attribute&.title
        if sample_attribute&.sample_attribute_type&.seek_sample_multi?
          attr_value = s.get_attribute_value(sample_attribute_title)
          attr_value&.any? { |v| v&.dig(:title)&.downcase&.include?(attribute_filter_value) }
        elsif sample_attribute&.sample_attribute_type&.seek_cv_list?
          attr_value = s.get_attribute_value(sample_attribute_title)
          attr_value&.any? { |v| v.downcase.include?(attribute_filter_value) }
				else
          s.get_attribute_value(sample_attribute_title)&.to_s&.downcase&.include?(attribute_filter_value)
        end
      end
    end

    if params[:input_template_id].present? && params[:input_attribute_id].present? # linked
      input_template_attribute =
        TemplateAttribute.find(params[:input_attribute_id])
      @result = filter_linked_samples(@result, :linked_samples,
                                      { attribute_id: params[:input_attribute_id],
          attribute_value: params[:input_attribute_value],
          template_id: params[:input_template_id] }, input_template_attribute)
    end

    if params[:output_template_id].present? && params[:output_attribute_id].present? # linking
      output_template_attribute =
        TemplateAttribute.find(params[:output_attribute_id])
      @result = filter_linked_samples(@result, :linking_samples,
                                      { attribute_id: params[:output_attribute_id],
          attribute_value: params[:output_attribute_value],
          template_id: params[:output_template_id] }, output_template_attribute)
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

  def batch_delete_sample_params(parameters = params)
    batch_params = []
    parameters[:data].each do |par|
      batch_params << par.permit(:id, :ex_id)
    end
    batch_params
  end

  def batch_upload_sample_params(parameters = params, sample_type_id)
    param_converter = Seek::Api::ParameterConverter.new("samples")
    batch_params = []
    parameters[:data].each do |par|
      converted_params = param_converter.convert(par)
      ex_id = par[:ex_id]
      sample_type = SampleType.find_by_id(sample_type_id)
      conv_par = sample_params(sample_type, converted_params).merge(ex_id: ex_id) unless ex_id.blank?
      if parameters[:action] == 'batch_update'
        sample_id = par[:id]
        conv_par.merge!(id: sample_id)
      end
      batch_params << conv_par
    end
    batch_params
  end

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
    parameters.require(:sample).permit(:sample_type_id, *creator_related_params, :observation_unit_id,
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
    if params[:sample_type_id]
      @sample_type = SampleType.includes(:sample_attributes).find(params[:sample_type_id])
      @samples = @sample_type.samples.authorized_for('view')
    elsif params[:template_id]
      @template = Template.find(params[:template_id])
      @samples = @template.samples.authorized_for('view')
    else
      find_assets
    end
  end

  # Filters linked samples based on the provided options and template attribute title.
  #
  # @param samples [Array<Sample>] the list of samples to filter
  # @param link [Symbol] the method to call on each sample to get the linked samples (:linked_samples or :linking_samples)
  # @param options [Hash] the options for filtering
  # @option options [Integer] :template_id the ID of the template to filter by
  # @option options [String] :attribute_value the value of the attribute to filter by
  # @option options [Integer] :attribute_id the ID of the attribute to filter by
  # @param template_attribute_title [String] the title of the template attribute to filter by
  # @return [Array<Sample>] the filtered list of samples
  def filter_linked_samples(samples, link, options, template_attribute)
    raise ArgumentError, "Invalid linking method provided. '#{link.to_s}' is not allowed!" unless %i[linked_samples linking_samples].include? link

    template_attribute_title = template_attribute&.title
    samples.select do |s|
      s.send(link).any? do |x|
        selected = x.sample_type.template_id == options[:template_id].to_i
        if template_attribute.sample_attribute_type.seek_sample_multi?
          selected = x.get_attribute_value(template_attribute_title)&.any? { |v| v&.dig(:title).downcase.include?(options[:attribute_value]) } if template_attribute.present? && selected
        elsif template_attribute.sample_attribute_type.seek_cv_list?
          selected = x.get_attribute_value(template_attribute_title)&.any? { |v| v.downcase.include?(options[:attribute_value]) } if template_attribute.present? && selected
				else
          selected = x.get_attribute_value(template_attribute_title)&.to_s&.downcase&.include?(options[:attribute_value]&.downcase) if template_attribute.present? && selected
        end
        selected || filter_linked_samples([x], link, options, template_attribute).present?
      end
    end
  end

  def templates_enabled?
    unless Seek::Config.isa_json_compliance_enabled
      flash[:error] = 'Not available'
      redirect_to select_sample_types_path
    end
  end

  def check_if_locked_sample_type
    return unless params[:sample_type_id]

    sample_type = SampleType.find(params[:sample_type_id])
    return unless sample_type&.locked?

    flash[:error] = 'This sample type is locked. You cannot edit the sample.'
    redirect_to sample_types_path(sample_type)
  end

  def authorize_sample_type
    id = params[:sample_type_id] || params.dig(:sample, :sample_type_id)
    return unless id

    sample_type = SampleType.find(id)
    unless sample_type.can_view?
      flash[:error] = "You are not authorized to use this #{t('sample_type')}"
      redirect_to root_path
    end

  end

end
