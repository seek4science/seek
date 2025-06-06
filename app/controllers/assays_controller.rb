class AssaysController < ApplicationController
  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :assays_enabled?
  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item,
                only: %i[edit update destroy manage manage_update show new_object_based_on_existing_one]

  # project_membership_required_appended is an alias to project_membership_required, but is necessary to include the actions
  # defined in the application controller
  before_action :project_membership_required_appended, only: [:new_object_based_on_existing_one]

  # Only for ISA JSON compliant assays
  # => Fix sample type linkage
  before_action :fix_assay_linkage_when_deleting_assays, only: :destroy
  # => Delete sample type of deleted assay
  before_action :delete_linked_sample_types, only: :destroy
  # => Rearrange positions
  after_action :rearrange_assay_positions_at_destroy, only: :destroy

  after_action :propagate_permissions_to_children, only: :manage_update

  include Seek::Publishing::PublishingCommon

  include Seek::ISAGraphExtensions

  api_actions :index, :show, :create, :update, :destroy

  def new_object_based_on_existing_one
    @existing_assay = Assay.find(params[:id])
    @assay = @existing_assay.clone_with_associations
    
    if @existing_assay.can_view?
      notice_message = ''
      unless @assay.study.can_edit?
        @assay.study = nil
        notice_message << "The #{t('study')} of the existing #{t('assays.assay')} cannot be viewed, please specify your own #{t('study')}! <br/>"
      end

      @existing_assay.data_files.each do |d|
        unless d.can_view?
          notice_message << "Some or all #{t('data_file').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>"
          break
        end
      end
      @existing_assay.sops.each do |s|
        unless s.can_view?
          notice_message << "Some or all #{t('sop').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>"
          break
        end
      end
      @existing_assay.models.each do |m|
        unless m.can_view?
          notice_message << "Some or all #{t('model').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>"
          break
        end
      end
      @existing_assay.documents.each do |d|
        unless d.can_view?
          notice_message << "Some or all #{t('document').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>"
          break
        end
      end

      flash.now[:notice] = notice_message.html_safe unless notice_message.blank?

      render action: 'new'
    else
      flash[:error] = "You do not have the necessary permissions to copy this #{t('assays.assay')}"
      redirect_to @existing_assay
    end
  end

  def new
    @assay = setup_new_asset
    @assay_class = params[:class]
    @permitted_params = assay_params if params[:assay]

    # jump straight to experimental if modelling analysis is disabled
    @assay_class ||= 'EXP' unless Seek::Config.modelling_analysis_enabled

    @assay.assay_class = AssayClass.for_type(@assay_class) unless @assay_class.nil?

    respond_to(&:html)
  end

  def edit
    if @assay.is_isa_json_compliant?
      redirect_to edit_isa_assay_path(@assay)
    else
      respond_to(&:html)
    end
  end

  def create
    params[:assay_class_id] ||= AssayClass.experimental.id
    @assay = Assay.new(assay_params)

    update_assay_organisms @assay, params
    update_assay_human_diseases @assay, params
    @assay.contributor = current_person
    update_sharing_policies @assay
    update_annotations(params[:tag_list], @assay)
    update_relationships(@assay, params)

    if @assay.save
      respond_to do |format|
        flash[:notice] = "#{t('assays.assay')} was successfully created."
        format.html { redirect_to(@assay) }
        format.json { render json: @assay, include: [params[:include]] }
      end
    else
      respond_to do |format|
        format.html { render action: 'new', status: :unprocessable_entity }
        format.json { render json: json_api_errors(@assay), status: :unprocessable_entity }
      end
    end
  end

  def update
    update_assay_organisms @assay, params
    update_assay_human_diseases @assay, params
    update_annotations(params[:tag_list], @assay)
    update_sharing_policies @assay
    update_relationships(@assay, params)

    respond_to do |format|
      if @assay.update(assay_params)
        flash[:notice] = "#{t('assays.assay')} was successfully updated."
        format.html { redirect_to(@assay) }
        format.json { render json: @assay, include: [params[:include]] }
      else
        format.html { render action: 'edit', status: :unprocessable_entity }
        format.json { render json: json_api_errors(@assay), status: :unprocessable_entity }
      end
    end
  end

  def update_assay_organisms(assay, params)
    organisms             = params[:assay_organism_ids] || params[:assay][:organism_ids] || []
    assay.assay_organisms = [] # This means new AssayOrganisms are created every time the assay is updated!
    Array(organisms).each do |text|
      # TODO: Refactor this to use proper nested params:
      o_id, strain, strain_id, culture_growth_type_text, t_id, t_title = text.split(',')
      culture_growth = CultureGrowthType.find_by_title(culture_growth_type_text)
      assay.associate_organism(o_id, strain_id, culture_growth, t_id, t_title)
    end
  end

  def update_assay_human_diseases(assay, params)
    human_diseases             = params[:assay_human_disease_ids] || params[:assay][:human_disease_ids] || []
    assay.assay_human_diseases = []
    Array(human_diseases).each do |human_disease_id|
      assay.associate_human_disease(human_disease_id)
    end
  end

  def show
    respond_to do |format|
      format.html { render(params[:only_content] ? { layout: false } : {}) }
      format.rdf { render template: 'rdf/show' }
      format.json { render json: @assay, include: [params[:include]] }
    end
  end

  private

  def propagate_permissions_to_children
    return unless params[:propagate_permissions] == '1'

    # Should only propagate permissions to child assays if the assay is an assay stream
    return unless @assay.is_assay_stream?

    errors = []
    @assay.child_assays.map do |assay|
      unless assay.can_manage?
        msg = "<li>You do not have the necessary permissions to propagate permissions to #{t('assay').downcase} [#{assay.id}]: '#{assay.title}'</li>"
        errors.append(msg)
        next
      end

      current_assay_policy = assay.policy
      # Clone the policy from the parent assay
      assay.update(policy: @assay.policy.deep_copy)
      current_assay_policy.destroy if current_assay_policy
      update_sharing_policies assay
    end
    # Add an error message to the flash
    flash[:error] = "<ul>#{errors.join('')}</ul>".html_safe unless errors.empty?
  end

  def delete_linked_sample_types
    return unless @assay.is_isa_json_compliant?
    return if @assay.sample_type.nil?

    @assay.sample_type.destroy
  end

  def fix_assay_linkage_when_deleting_assays
    return unless @assay.is_isa_json_compliant?
    return unless @assay.has_linked_child_assay?

    previous_st = @assay.sample_type&.previous_linked_sample_type
    next_st = @assay.sample_type&.next_linked_sample_types&.first
    return unless previous_st && next_st

    next_st.sample_attributes.detect(&:input_attribute?).update_column(:linked_sample_type_id, previous_st&.id)
  end

  def rearrange_assay_positions_at_destroy
    rearrange_assay_positions(@assay.assay_stream)
  end

  def assay_params
    params.require(:assay).permit(:title, :description, :study_id, :assay_class_id, :assay_type_uri, :technology_type_uri,
                                  :license, *creator_related_params, :position, { document_ids: [] },
                                  { sop_ids: [] }, { model_ids: [] },
                                  { samples_attributes: %i[asset_id direction] },
                                  { data_files_attributes: %i[asset_id direction relationship_type_id] },
                                  { placeholders_attributes: %i[asset_id direction relationship_type_id] },
                                  { publication_ids: [] },
                                  { extended_metadata_attributes: determine_extended_metadata_keys },
                                  { discussion_links_attributes: %i[id url label _destroy] }).tap do |assay_params|
      assay_params[:document_ids].select! { |id| Document.find_by_id(id).try(:can_view?) } if assay_params.key?(:document_ids)
      assay_params[:sop_ids].select! { |id| Sop.find_by_id(id).try(:can_view?) } if assay_params.key?(:sop_ids)
      assay_params[:model_ids].select! { |id| Model.find_by_id(id).try(:can_view?) } if assay_params.key?(:model_ids)
    end
  end
end
