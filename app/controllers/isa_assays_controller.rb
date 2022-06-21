class IsaAssaysController < ApplicationController
  include Seek::AssetsCommon
  before_action :set_up_instance_variable
  
  def new
    @isa_assay = IsaAssay.new
  end

  def create
    @isa_assay = IsaAssay.new(isa_assay_params)
    update_sharing_policies @isa_assay.assay
    @isa_assay.assay.contributor=current_person
    @isa_assay.sample_type.contributor = User.current_user.person

    if @isa_assay.save
			redirect_to single_page_path(id: @isa_assay.assay.projects.first, item_type: 'assay',
				item_id: @isa_assay.assay, notice: 'The ISA assay was created successfully!') 
		else
      respond_to do |format|
        format.html { render action: 'new' }
        format.json { render json: @isa_assay.errors, status: :unprocessable_entity}
      end
    end
  end

  private

  def isa_assay_params
    # TODO get the params from a shared module
    isa_assay_params = params.require(:isa_assay).permit({ assay: assay_params, sample_type: sample_type_params(params[:isa_assay]) }, :input_sample_type_id)
    params[:isa_assay][:assay][:document_ids].select! { |id| Document.find_by_id(id).try(:can_view?) } if isa_assay_params.key?(:document_ids)
    params[:isa_assay][:assay][:sop_ids].select! { |id| Sop.find_by_id(id).try(:can_view?) } if isa_assay_params.key?(:sop_ids)
    params[:isa_assay][:assay][:model_ids].select! { |id| Model.find_by_id(id).try(:can_view?) } if isa_assay_params.key?(:model_ids)
    isa_assay_params
  end

  def assay_params
   [:title, :description, :study_id, :assay_class_id, :assay_type_uri, :technology_type_uri,
    :license, *creator_related_params, :position, { document_ids: []},
    { scales: [] }, { sop_ids: [] }, { model_ids: [] },
    { samples_attributes: [:asset_id, :direction] },
    { data_files_attributes: [:asset_id, :direction, :relationship_type_id] },
    { publication_ids: [] },				  	
    { custom_metadata_attributes: determine_custom_metadata_keys },
    { discussion_links_attributes:[:id, :url, :label, :_destroy] }]
  end

  def sample_type_params (params)
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

    return [:title, :description, :tags, :template_id,
      { project_ids: [],
        sample_attributes_attributes: [:id, :title, :pos, :required, :is_title,
                                      :sample_attribute_type_id, :isa_tag_id,
                                      :sample_controlled_vocab_id,
                                      :linked_sample_type_id,
                                      :description, :iri,
                                      :unit_id, :_destroy]},assay_ids:[]]
  end

  def set_up_instance_variable
    @single_page = true
  end
end
