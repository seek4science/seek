class IsaAssaysController < ApplicationController
  include Seek::AssetsCommon
  include Seek::Publishing::PublishingCommon

  before_action :set_up_instance_variable
  before_action :find_requested_item, only: %i[edit update]
  before_action :initialize_isa_assay, only: :create
  after_action :rearrange_assay_positions_create_isa_assay, only: :create
  after_action :fix_assay_linkage_for_new_assays, only: :create

  def new
    study = Study.find(params[:study_id])
    new_position =
      if params[:is_assay_stream] || params[:source_assay_id].nil? # If first assay is of class assay stream
        study.assay_streams.any? ? study.assay_streams.map(&:position).max + 1 : 0
      elsif params[:source_assay_id] == params[:assay_stream_id] # If first assay in the stream
        0
      else
        Assay.find(params[:source_assay_id]).position + 1
      end

    source_assay = Assay.find(params[:source_assay_id]) if params[:source_assay_id]
    input_sample_type_id =
      if params[:is_assay_stream] || source_assay&.is_assay_stream?
        study.sample_types.second.id
      else
        source_assay&.sample_type&.id
      end

    @isa_assay =
      if params[:is_assay_stream]
        IsaAssay.new({ assay: { assay_class_id: AssayClass.assay_stream.id,
                                study_id: study.id,
                                position: new_position },
                       input_sample_type_id: })
      else
        IsaAssay.new({ assay: { assay_class_id: AssayClass.experimental.id,
                                assay_stream_id: params[:assay_stream_id],
                                study_id: study.id,
                                position: new_position },
                       input_sample_type_id: })
      end
    respond_to(&:html)
  end

  def create
    if @isa_assay.save
      flash[:notice] = "The #{t('isa_assay')} was successfully created.<br/>".html_safe
      respond_to do |format|
        format.html do
          redirect_to single_page_path(id: @isa_assay.assay.projects.first, item_type: 'assay',
                                       item_id: @isa_assay.assay)
        end
        format.json { render json: @isa_assay, include: [params[:include]] }
      end
    else
      respond_to do |format|
        format.html { render action: 'new', status: :unprocessable_entity }
        format.json { render json: json_api_errors(@isa_assay), status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to(&:html)
  end

  def update
    @isa_assay.assay.attributes = isa_assay_params[:assay]

    # update the sample_type
    unless @isa_assay&.assay&.is_assay_stream?
      if requested_item_authorized?(@isa_assay.sample_type)
        @isa_assay.sample_type.update(isa_assay_params[:sample_type])
        @isa_assay.sample_type.resolve_inconsistencies
      end
    end

    if @isa_assay.save
      flash[:notice] = "The #{t('isa_assay')} was successfully updated.<br/>".html_safe
      redirect_to single_page_path(id: @isa_assay.assay.projects.first, item_type: 'assay',
                                   item_id: @isa_assay.assay.id)
    else
      respond_to do |format|
        format.html { render action: 'edit', status: :unprocessable_entity }
        format.json { render json: @isa_assay.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def fix_assay_linkage_for_new_assays
    return unless @isa_assay.assay.is_isa_json_compliant?
    return if @isa_assay.assay.is_assay_stream? # Should not fix anything when creating an assay stream
    return unless @isa_assay.sample_type.present? # Just to be sure

    previous_sample_type = SampleType.find(params[:isa_assay][:input_sample_type_id])
    next_sample_types = previous_sample_type.next_linked_sample_types
    next_sample_types.delete @isa_assay.sample_type
    next_sample_type = next_sample_types.first

    # In case an assay is inserted right at the end of an assay stream,
    # there is no next sample type and also no linkage to fix
    return if next_sample_type.nil?

    next_sample_type.sample_attributes.detect(&:input_attribute?).update_column(:linked_sample_type_id, @isa_assay.sample_type.id)
  end

  def rearrange_assay_positions_create_isa_assay
    return if @isa_assay.assay.is_assay_stream?
    return unless @isa_assay.assay.is_isa_json_compliant?

    rearrange_assay_positions(@isa_assay.assay.assay_stream)
  end

  def initialize_isa_assay
    @isa_assay = IsaAssay.new(isa_assay_params)
    update_sharing_policies @isa_assay.assay
    @isa_assay.assay.contributor = current_person
    @isa_assay.sample_type.contributor = User.current_user.person if isa_assay_params[:sample_type]
  end

  def isa_assay_params
    # TODO: get the params from a shared module
    isa_assay_params = params.require(:isa_assay).permit(
      { assay: assay_params, sample_type: sample_type_params(params[:isa_assay]) }, :input_sample_type_id
    )
    if isa_assay_params.key?(:document_ids)
      params[:isa_assay][:assay][:document_ids].select! do |id|
        Document.find_by_id(id).try(:can_view?)
      end
    end
    if isa_assay_params.key?(:sop_ids)
      params[:isa_assay][:assay][:sop_ids].select! do |id|
        Sop.find_by_id(id).try(:can_view?)
      end
    end
    if isa_assay_params.key?(:model_ids)
      params[:isa_assay][:assay][:model_ids].select! do |id|
        Model.find_by_id(id).try(:can_view?)
      end
    end
    isa_assay_params
  end

  def assay_params
    [:title, :description, :study_id, :assay_class_id, :assay_type_uri, :technology_type_uri,
     :license, *creator_related_params, :position, { document_ids: [] },
     { scales: [] }, { sop_ids: [] }, { model_ids: [] },
     { samples_attributes: %i[asset_id direction] },
     { data_files_attributes: %i[asset_id direction relationship_type_id] },
     { publication_ids: [] },
     { extended_metadata_attributes: determine_extended_metadata_keys(:assay) },
     { discussion_links_attributes: %i[id url label _destroy] }, :assay_stream_id]
  end

  def sample_type_params(params)
    return [] unless params[:sample_type]

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

  def set_up_instance_variable
    @single_page = true
  end

  def find_requested_item
    @isa_assay = IsaAssay.new
    @isa_assay.populate(params[:id])

    if @isa_assay.assay.nil?
      @isa_assay.errors.add(:assay, "The #{t('isa_assay')} was not found.")
    else
      @isa_assay.errors.add(:assay, "You are not authorized to edit this #{t('isa_assay')}.") unless requested_item_authorized?(@isa_assay.assay)
    end

    # Should not deal with sample type if assay has assay_class assay stream
    unless @isa_assay.assay&.is_assay_stream?
      if @isa_assay.sample_type.nil?
        @isa_assay.errors.add(:sample_type, 'Sample type not found.')
      else
        @isa_assay.errors.add(:sample_type, "You are not authorized to edit this assay's #{t('sample_type')}.") unless requested_item_authorized?(@isa_assay.sample_type)
      end
    end

    if @isa_assay.errors.any?
      error_messages = @isa_assay.errors.map do |error|
        "<li>[<b>#{error.attribute.to_s}</b>]: #{error.message}</li>"
      end.join('')
      flash[:error] = "<ul>#{error_messages}</ul>".html_safe
      redirect_to single_page_path(id: @isa_assay.assay.projects.first, item_type: 'assay',
                                   item_id: @isa_assay.assay)
    end
  end
end
