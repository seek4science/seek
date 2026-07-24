class ISAStudiesController < ApplicationController
  include Seek::AssetsCommon
  include Seek::Publishing::PublishingCommon

  before_action :set_up_instance_variable
  before_action :find_requested_item_for_edit, only: %i[edit update]
  before_action :find_requested_item_for_show, only: :show
  before_action :old_attributes, only: %i[update]

  after_action :update_sample_json_metadata, only: :update

  api_actions :create, :update, :show

  def show
    respond_to do |format|
      format.json { render json: @isa_study, include: [params[:include]] }
      format.html do
        flash[:notice] = "You have been redirected to the #{t('single_page')} view"
        redirect_to single_page_path(id: @isa_study.study.projects.first, item_type: 'study',
                                     item_id: @isa_study.study)
      end
    end
  end

  def new
    @isa_study = ISAStudy.new({ study: { investigation_id: params[:investigation_id] } })
  end

  def create
    @isa_study = ISAStudy.new(isa_study_params)
    update_sharing_policies @isa_study.study
    @isa_study.source.policy = @isa_study.study.policy
    @isa_study.sample_collection.policy = @isa_study.study.policy
    @isa_study.source.contributor = User.current_user.person
    @isa_study.sample_collection.contributor = User.current_user.person
    @isa_study.source.title = "#{@isa_study.study.title} - Source Sample Type" if @isa_study.source.title.blank?
    @isa_study.source.description = "Source Sample Type linked to Study '#{@isa_study.study.title}'." if @isa_study.source.description.blank?
    @isa_study.sample_collection.title = "#{@isa_study.study.title} - Sample Collection Sample Type" if @isa_study.sample_collection.title.blank?
    @isa_study.sample_collection.description = "Sample Collection Sample Type linked to Study '#{@isa_study.study.title}'." if @isa_study.sample_collection.description.blank?
    @isa_study.study.sample_types = [ @isa_study.source, @isa_study.sample_collection ]

    if @isa_study.save
      flash[:notice] = "The #{t('isa_study')} was successfully created"

      respond_to do |format|
        format.html do
          redirect_to single_page_path(id: @isa_study.study.projects.first, item_type: 'study',
                                       item_id: @isa_study.study)
        end
        format.json { render json: @isa_study, include: [params[:include]], status: :created }
      end

    else
      respond_to do |format|
        format.html { render action: 'new', status: :unprocessable_entity }
        format.json { render json: json_api_errors(@isa_study), status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to(&:html)
  end

  def update
    # update the study
    @isa_study.study.attributes = isa_study_params[:study]
    update_sharing_policies @isa_study.study
    @isa_study.source.policy = @isa_study.study.policy
    @isa_study.sample_collection.policy = @isa_study.study.policy
    update_relationships(@isa_study.study, isa_study_params[:study]) unless isa_study_params[:study].nil?

    # update the source
    if requested_item_authorized?(@isa_study.source)
      @isa_study.source.update(isa_study_params[:source_sample_type])
      @isa_study.source.resolve_inconsistencies
    end

    # update the sample collection
    if requested_item_authorized?(@isa_study.sample_collection)
      @isa_study.sample_collection.update(isa_study_params[:sample_collection_sample_type])
      @isa_study.sample_collection.resolve_inconsistencies
    end

    if @isa_study.save
      respond_to do |format|
        format.html do
          flash[:notice] = "The #{t('isa_study')} was successfully updated"
          redirect_to single_page_path(id: @isa_study.study.projects.first, item_type: 'study',
                                       item_id: @isa_study.study.id)

        end

        format.json { render json: @isa_study, include: [params[:include]], status: :ok }
      end
    else
      respond_to do |format|
        format.html { render action: 'edit', status: :unprocessable_entity }
        format.json { render json: json_api_errors(@isa_study), status: :unprocessable_entity }
      end
    end
  end

  private

  def isa_study_params
    # TODO: get the params from a shared module
    params.require(:isa_study).permit({ study: study_params,
                                        source_sample_type: sample_type_params(params[:isa_study],
                                                                               'source_sample_type'),
                                        sample_collection_sample_type: sample_type_params(params[:isa_study],
                                                                                          'sample_collection_sample_type') })
  end

  def study_params
    [:title, :description, :experimentalists, :investigation_id, { sop_ids: [] },
     *creator_related_params, :position, { scales: [] }, { publication_ids: [] },
     { discussion_links_attributes: %i[id url label _destroy] },
     { extended_metadata_attributes: determine_extended_metadata_keys(:study) }]
  end

  def sample_type_params(params, field)
    return {} if params[field].nil?

    attributes = params[field][:sample_attributes]
    if attributes
      params[field][:sample_attributes_attributes] = []
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
        params[field][:sample_attributes_attributes] << attribute
      end
    end

    if params[field][:assay_assets_attributes]
      params[field][:assay_ids] = params[field][:assay_assets_attributes].map { |x| x[:assay_id] }
    end

    [:title, :description, :tags, :template_id,
     { project_ids: [],
       sample_attributes_attributes: %i[id title pos required is_title
                                        sample_attribute_type_id isa_tag_id
                                        sample_controlled_vocab_id
                                        linked_sample_type_id
                                        template_attribute_id
                                        description pid
                                        allow_cv_free_text
                                        unit_id _destroy] }, { assay_ids: [] }]
  end

  def old_attributes
    @old_sample_type_attributes = {}
    { source: @isa_study.source, sample_collection: @isa_study.sample_collection }.each do |key, sample_type|
      next if sample_type&.sample_attributes.blank?

      @old_sample_type_attributes[key] = sample_type.sample_attributes.map { |attr| { id: attr.id, title: attr.title } }
    end
  end

  def update_sample_json_metadata

    # Update source sample metadata
    attribute_changes = {}
    if !@isa_study.source.samples.blank? && !@old_sample_type_attributes[:source].blank?
      attribute_changes[:source] = @isa_study.source.sample_attributes.map do |attr|
        old_attr = @old_sample_type_attributes[:source].detect { |oa| oa[:id] == attr.id }
        next if old_attr.nil?

        { id: attr.id, old_title: old_attr[:title], new_title: attr.title } unless old_attr[:title] == attr.title
      end.compact
      UpdateSampleMetadataJob.perform_later(@isa_study.source, @current_user, attribute_changes[:source]) unless attribute_changes[:source].blank?
    end

    # Update sample collection sample metadata
    if !@isa_study.sample_collection.samples.blank? && !@old_sample_type_attributes[:sample_collection].blank?
      attribute_changes[:sample_collection] = @isa_study.sample_collection.sample_attributes.map do |attr|
        old_attr = @old_sample_type_attributes[:sample_collection].detect { |oa| oa[:id] == attr.id }
        next if old_attr.nil?

        { id: attr.id, old_title: old_attr[:title], new_title: attr.title } unless old_attr[:title] == attr.title
      end.compact
      UpdateSampleMetadataJob.perform_later(@isa_study.sample_collection, @current_user, attribute_changes[:sample_collection]) unless attribute_changes[:sample_collection].blank?
    end
  end

  def set_up_instance_variable
    @single_page = true
  end

  def respond_with_error(status=:unprocessable_entity)
    respond_to do |format|
      format.html do
        error_messages = @isa_study.errors.map do |error|
          helpers.content_tag(:li) do
            "[" + helpers.content_tag(:b, error.attribute.to_s) + "]: #{ERB::Util.html_escape(error.message)}"
          end
        end
        flash[:error] = helpers.content_tag(:ul) do
          helpers.safe_join(error_messages)
        end.html_safe
        path = if @isa_study.study.nil?
                 studies_path
               else
                 single_page_path(id: @isa_study.study.projects.first, item_type: 'study',
                                  item_id: @isa_study.study)
               end
        redirect_to path
      end

      format.json { render json: json_api_errors(@isa_study), status: status }
    end
  end

  def find_requested_item_for_show
    @isa_study = ISAStudy.new
    @isa_study.populate(params[:id])

    # Check whether base objects exist
    @isa_study.errors.add(:study, "The #{t('isa_study')} was not found.") if @isa_study.study.nil?
    @isa_study.errors.add(:sample_type, "'#{t('isa_study')} source' #{t('sample_type')} not found.") if @isa_study.source.nil?
    @isa_study.errors.add(:sample_type, "'#{t('isa_study')} sample' #{t('sample_type')} not found.") if @isa_study.sample_collection.nil?
    return respond_with_error(:not_found) if @isa_study.errors.any?

    # Check authorizations
    @isa_study.errors.add(:study, "You are not authorized to view this #{t('isa_study')}.") unless @isa_study.study.can_view?
    return respond_with_error(:forbidden) if @isa_study.errors.any?

  rescue ActiveRecord::RecordNotFound
    render json: { errors: [{ title: 'Not Found', detail: "#{t('isa_study')} with id '#{params[:id]}' was not found." }] },
           status: :not_found
    return false
  end

  def find_requested_item_for_edit
    @isa_study = ISAStudy.new
    @isa_study.populate(params[:id])

    # Check whether base objects exist
    @isa_study.errors.add(:study, "The #{t('isa_study')} was not found.") if @isa_study.study.nil?
    @isa_study.errors.add(:sample_type, "'#{t('isa_study')} source' #{t('sample_type')} not found.") if @isa_study.source.nil?
    @isa_study.errors.add(:sample_type, "'#{t('isa_study')} sample' #{t('sample_type')} not found.") if @isa_study.sample_collection.nil?
    return respond_with_error(:not_found) if @isa_study.errors.any?

    # Check authorizations
    @isa_study.errors.add(:study, "You are not authorized to edit this #{t('isa_study')}.") unless requested_item_authorized?(@isa_study.study)
    @isa_study.errors.add(:sample_type, "You are not authorized to edit the '#{t('isa_study')} source' #{t('sample_type')}.") unless requested_item_authorized?(@isa_study.source)
    @isa_study.errors.add(:sample_type, "You are not authorized to edit the '#{t('isa_study')} sample collection' #{t('sample_type')}.") unless requested_item_authorized?(@isa_study.sample_collection)
    return respond_with_error(:forbidden) if @isa_study.errors.any?

    # Check whether sample types are locked
    @isa_study.errors.add(:sample_type, "'#{t('isa_study')} source' #{t('sample_type')} is locked by a background process.") if @isa_study.source&.locked?
    @isa_study.errors.add(:sample_type, "'#{t('isa_study')} sample' #{t('sample_type')} is locked by a background process.") if @isa_study.sample_collection&.locked?
    return respond_with_error(:unprocessable_entity) if @isa_study.errors.any?
  end
end
