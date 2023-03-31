class IsaStudiesController < ApplicationController
  include Seek::AssetsCommon
  include Seek::Publishing::PublishingCommon

  before_action :set_up_instance_variable
  before_action :find_requested_item, only: %i[edit update]

  def new
    @isa_study = IsaStudy.new
  end

  def create
    @isa_study = IsaStudy.new(isa_study_params)
    update_sharing_policies @isa_study.study
    @isa_study.source.contributor = User.current_user.person
    @isa_study.sample_collection.contributor = User.current_user.person
    @isa_study.study.sample_types = [@isa_study.source, @isa_study.sample_collection]

    if @isa_study.save
      flash[:notice] = "The #{t('isa_study')} was succesfully created.<br/>".html_safe

      respond_to do |format|
        format.html do
          redirect_to single_page_path(id: @isa_study.study.projects.first, item_type: 'study',
                                       item_id: @isa_study.study)
        end
        format.json { render json: @isa_study, include: [params[:include]] }
      end

    else
      respond_to do |format|
        format.html { render action: 'new' }
        format.json { render json: @isa_study.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @isa_study.source = nil unless requested_item_authorized?(@isa_study.source)
    @isa_study.sample_collection = nil unless requested_item_authorized?(@isa_study.sample_collection)

    respond_to do |format|
      format.html
    end
  end

  def update
    # update the study
    @isa_study.study.attributes = isa_study_params[:study]
    update_sharing_policies @isa_study.study
    update_relationships(@isa_study.study, isa_study_params[:study])

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
      redirect_to single_page_path(id: @isa_study.study.projects.first, item_type: 'study',
                                   item_id: @isa_study.study.id)
    else
      respond_to do |format|
        format.html { render action: 'edit', status: :unprocessable_entity }
        format.json { render json: @isa_study.errors, status: :unprocessable_entity }
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
     { custom_metadata_attributes: determine_custom_metadata_keys }]
  end

  def sample_type_params(params, field)
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
                                        description pid
                                        unit_id _destroy] }, { assay_ids: [] }]
  end

  def set_up_instance_variable
    @single_page = true
  end

  def find_requested_item
    @isa_study = IsaStudy.new
    @isa_study.populate(params[:id])
    unless requested_item_authorized?(@isa_study.study)
      flash[:error] = "You are not authorized to edit this #{t('isa_study')}"
      redirect_to single_page_path(id: @isa_study.study.projects.first, item_type: 'study',
                                   item_id: @isa_study.study)
    end
  end
end
