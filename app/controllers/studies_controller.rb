class StudiesController < ApplicationController
  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, only: %i[edit update destroy manage manage_update show new_object_based_on_existing_one]

  # project_membership_required_appended is an alias to project_membership_required, but is necesary to include the actions
  # defined in the application controller
  before_action :project_membership_required_appended, only: [:new_object_based_on_existing_one]

  before_action :check_assays_are_not_already_associated_with_another_study, only: %i[create update]

  include Seek::Publishing::PublishingCommon

  include Seek::AnnotationCommon

  include Seek::BreadCrumbs

  include Seek::IsaGraphExtensions

  def new_object_based_on_existing_one
    @existing_study = Study.find(params[:id])

    if @existing_study.can_view?
      @study = @existing_study.clone_with_associations
      unless @existing_study.investigation.can_edit?
        @study.investigation = nil
        flash.now[:notice] = "The #{t('investigation')} associated with the original #{t('study')} cannot be edited, so you need to select a different #{t('investigation')}"
      end
      render action: 'new'
    else
      flash[:error] = "You do not have the necessary permissions to copy this #{t('study')}"
      redirect_to study_path(@existing_study)
    end
  end

  def new
    @study = Study.new
    @study.create_from_asset = params[:create_from_asset]
    investigation = nil
    investigation = Investigation.find(params[:investigation_id]) if params[:investigation_id]

    if investigation
      if investigation.can_edit?
        @study.investigation = investigation
      else
        flash.now[:error] = "You do not have permission to associate the new #{t('study')} with the #{t('investigation')} '#{investigation.title}'."
      end
    end
    investigations = Investigation.all.select(&:can_view?)
    respond_to do |format|
      if investigations.blank?
        flash.now[:notice] = "No #{t('investigation')} available, you have to create a new one before creating your Study!"
      end
      format.html
    end
  end

  def edit
    @study = Study.find(params[:id])
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def update
    @study = Study.find(params[:id])
    @study.attributes = study_params
    update_sharing_policies @study
    update_relationships(@study, params)

    respond_to do |format|
      if @study.save
        flash[:notice] = "#{t('study')} was successfully updated."
        format.html { redirect_to(@study) }
        format.json {render json: @study}
      else
        format.html { render action: 'edit', status: :unprocessable_entity }
        format.json { render json: json_api_errors(@study), status: :unprocessable_entity }
      end
    end
  end

  def show
    @study = Study.find(params[:id])
    @study.create_from_asset = params[:create_from_asset]

    respond_to do |format|
      format.html
      format.xml
      format.rdf { render template: 'rdf/show' }
      format.json {render json: @study}
    end
  end

  def create
    @study = Study.new(study_params)
    update_sharing_policies @study
    update_relationships(@study, params)
    ### TO DO: what about validation of person responsible? is it already included (for json?)
    if @study.save
      respond_to do |format|
        flash[:notice] = "The #{t('study')} was successfully created.<br/>".html_safe
        if @study.create_from_asset == 'true'
          flash.now[:notice] << "Now you can create new #{t('assays.assay')} by clicking -Add an #{t('assays.assay')}- button".html_safe
          format.html { redirect_to study_path(id: @study, create_from_asset: @study.create_from_asset) }
          format.json { render json: @study }
        else
          format.html { redirect_to study_path(@study) }
          format.json { render json: @study }
        end
      end
    else
      respond_to do |format|
        format.html { render action: 'new', status: :unprocessable_entity }
        format.json { render json: json_api_errors(@study), status: :unprocessable_entity }
      end
    end
  end

  def investigation_selected_ajax
    if (investigation_id = params[:investigation_id]).present? && params[:investigation_id] != '0'
      investigation = Investigation.find(investigation_id)
      people = investigation.projects.collect(&:people).flatten
    end

    people ||= []

    render partial: 'studies/person_responsible_list', locals: { people: people }
  end

  def check_assays_are_not_already_associated_with_another_study
    assay_ids = params[:study][:assay_ids]
    study_id = params[:id]
    if assay_ids
      valid = !assay_ids.detect do |a_id|
        a = Assay.find(a_id)
        !a.study.nil? && a.study_id.to_s != study_id
      end
      unless valid
        unless valid
          error("Cannot add an #{t('assays.assay')} already associated with a Study", "is invalid (invalid #{t('assays.assay')})")
          return false
        end
      end
    end
  end

  private
  def validate_person_responsible(p)
    if (!p[:person_responsible_id].nil?) && (!Person.exists?(p[:person_responsible_id]))
      render json: {error: "Person responsible does not exist", status: :unprocessable_entity}, status: :unprocessable_entity
      return false
    end
    true
  end

  def study_params
    params.require(:study).permit(:title, :description, :experimentalists, :investigation_id, :person_responsible_id,
                                  :other_creators, :create_from_asset, { creator_ids: [] },
                                  { scales: [] }, { publication_ids: [] })
  end
end
